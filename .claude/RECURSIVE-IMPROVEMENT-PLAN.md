# Recursive Improvement Plan - OrcaSlicer Feature Hardening
**Date:** 2026-02-14
**Based On:** Gap Analysis + Creative Solutions
**Timeline:** 4 weeks (47-48 hours development time)
**Methodology:** Iterative improvement with testing feedback loops
**Goal:** Production-ready implementation of all 6 features

---

## Overview

This plan addresses 47 identified gaps across 6 features through 5 iterative phases. Each phase builds on the previous, with testing and validation at every step.

### Success Criteria

**Phase 1 Complete:** No crashes in normal usage
**Phase 2 Complete:** Undo/redo fully functional
**Phase 3 Complete:** All configurations validated
**Phase 4 Complete:** User expectations met
**Phase 5 Complete:** Production-ready with test coverage

---

## Phase 1: Stop the Bleeding (Critical Crashes)
**Duration:** 2 hours
**Risk Level:** 🟢 LOW
**Goal:** Prevent data loss and crashes

### Tasks

#### Task 1.1: Fix Volume Deletion Dangling Pointer ⚠️ CRITICAL
**Feature:** #5 (Hierarchical Groups)
**Time:** 30 minutes
**Files:** `src/libslic3r/Model.cpp:1315-1340`

**Implementation:**
```cpp
void ModelObject::delete_volume(size_t idx) {
    ModelVolumePtrs::iterator i = this->volumes.begin() + idx;
    ModelVolume* vol = *i;

    // ✅ ADD: Remove from group before deleting
    if (vol->parent_group) {
        vol->parent_group->remove_volume(vol);

        // Clean up empty groups
        if (vol->parent_group->volumes.empty()) {
            this->delete_volume_group(vol->parent_group->id);
        }
    }

    delete *i;
    this->volumes.erase(i);

    // ... existing code continues ...
}
```

**Test:**
```cpp
TEST_CASE("delete_volume removes from group") {
    ModelObject obj;
    ModelVolume* vol = obj.add_volume(TriangleMesh());
    ModelVolumeGroup* group = obj.add_volume_group("Test");
    obj.move_volume_to_group(vol, group);

    obj.delete_volume(0);

    REQUIRE(group->volumes.empty());  // Should not crash
}
```

**Validation:**
- ✅ Run test suite
- ✅ Manual test: Create group → Add volumes → Delete one → Save project
- ✅ No crashes or errors

---

#### Task 1.2: Fix Clear Volumes Dangling Pointer ⚠️ CRITICAL
**Feature:** #5 (Hierarchical Groups)
**Time:** 15 minutes
**Files:** `src/libslic3r/Model.cpp:1342-1350`

**Implementation:**
```cpp
void ModelObject::clear_volumes() {
    // ✅ ADD: Clean up groups before clearing volumes
    for (auto& group : volume_groups) {
        group->volumes.clear();
    }
    volume_groups.clear();

    // Existing code
    for (size_t i = 0; i < this->volumes.size(); ++i) {
        ModelVolume* v = this->volumes[i];
        delete v;
    }
    this->volumes.clear();
}
```

**Validation:**
- ✅ Manual test: Create grouped object → Clear all → Save
- ✅ No crashes

---

#### Task 1.3: Add Null Pointer Checks ⚠️ HIGH
**Feature:** #2 (Per-Plate Settings)
**Time:** 1 hour
**Files:** `src/slic3r/GUI/PartPlate.cpp:2486, 2496, 2509`

**Implementation:**
```cpp
// Line 2486: Check extruder_count option
auto extruder_count_opt = printer_preset->config.option<ConfigOptionInt>("extruder_count");
if (!extruder_count_opt) {
    warnings += "Printer preset is missing 'extruder_count' option. ";
    has_warnings = true;
    continue;  // Skip this validation
}
int printer_extruder_count = extruder_count_opt->value;

// Line 2496: Check printable_area option
auto printable_area_opt = printer_preset->config.option<ConfigOptionPoints>("printable_area");
if (!printable_area_opt) {
    warnings += "Printer preset is missing 'printable_area' option. ";
    has_warnings = true;
    continue;
}
const Points& printable_area = printable_area_opt->values;

// Line 2509: Similar checks for other options
```

**Validation:**
- ✅ Create corrupted preset (missing options) → Open plate settings
- ✅ Should show warning, not crash

---

### Phase 1 Checkpoint
**Review Meeting:** After 2 hours
**Deliverables:**
- 3 crash bugs fixed
- Manual testing complete
- Unit tests passing

**Go/No-Go Decision:**
- ✅ All tests pass → Proceed to Phase 2
- ❌ Tests fail → Debug and retry

---

## Phase 2: Restore Undo/Redo (Data Preservation)
**Duration:** 6-7 hours
**Risk Level:** 🟡 LOW-MEDIUM
**Goal:** Undo/redo fully functional for all features

### Tasks

#### Task 2.1: Groups Undo/Redo Serialization ⚠️ CRITICAL
**Feature:** #5 (Hierarchical Groups)
**Time:** 3-4 hours
**Files:** `src/libslic3r/Model.hpp:733-759, Model.cpp`

**Implementation Steps:**

**Step 1:** Add cereal serialization to ModelVolumeGroup (1 hour)
```cpp
// Model.hpp - Add to ModelVolumeGroup class
template<class Archive> void save(Archive& ar) const {
    ar(cereal::base_class<ObjectBase>(this));
    ar(name, id, extruder_id, visible);

    // Save volume indices (not pointers - they'll be invalid after load)
    std::vector<size_t> volume_indices;
    for (ModelVolume* vol : volumes) {
        auto it = std::find_if(parent_object->volumes.begin(),
                              parent_object->volumes.end(),
                              [vol](const std::unique_ptr<ModelVolume>& v) {
                                  return v.get() == vol;
                              });
        if (it != parent_object->volumes.end()) {
            volume_indices.push_back(std::distance(parent_object->volumes.begin(), it));
        }
    }
    ar(volume_indices);
}

template<class Archive> void load(Archive& ar) {
    ar(cereal::base_class<ObjectBase>(this));
    ar(name, id, extruder_id, visible);

    std::vector<size_t> volume_indices;
    ar(volume_indices);

    // Rebuild volume pointers from indices
    volumes.clear();
    for (size_t idx : volume_indices) {
        if (idx < parent_object->volumes.size()) {
            volumes.push_back(parent_object->volumes[idx].get());
        }
    }
}

// Add friend declaration
friend class cereal::access;
```

**Step 2:** Include volume_groups in ModelObject serialization (1 hour)
```cpp
// Model.hpp:737 - Add to save()
template<class Archive> void save(Archive& ar) const {
    ar(cereal::base_class<ObjectBase>(this));
    // ... existing fields ...
    ar(name, module_name, input_file, instances, volumes, config_wrapper,
       layer_config_ranges, layer_heigth_profile_wrapper,
       sla_support_points, sla_points_status, sla_drain_holes, printable,
       origin_translation, brim_points,
       m_bounding_box_approx, m_bounding_box_approx_valid,
       m_bounding_box_exact, m_bounding_box_exact_valid, m_min_max_z_valid,
       m_raw_bounding_box, m_raw_bounding_box_valid,
       m_raw_mesh_bounding_box, m_raw_mesh_bounding_box_valid,
       cut_connectors, cut_id,
       volume_groups);  // ✅ ADD THIS
}

// Model.hpp:750 - Add to load()
template<class Archive> void load(Archive& ar) {
    ar(cereal::base_class<ObjectBase>(this));
    // ... existing fields ...
    ar(name, module_name, input_file, instances, volumes, config_wrapper,
       layer_config_ranges, layer_heigth_profile_wrapper,
       sla_support_points, sla_points_status, sla_drain_holes, printable,
       origin_translation, brim_points,
       m_bounding_box_approx, m_bounding_box_approx_valid,
       m_bounding_box_exact, m_bounding_box_exact_valid, m_min_max_z_valid,
       m_raw_bounding_box, m_raw_bounding_box_valid,
       m_raw_mesh_bounding_box, m_raw_mesh_bounding_box_valid,
       cut_connectors, cut_id,
       volume_groups);  // ✅ ADD THIS

    // ✅ ADD: Rebuild parent_object back-references
    for (auto& group : volume_groups) {
        group->parent_object = this;
    }

    // ✅ ADD: Rebuild volume→group back-references
    for (auto& group : volume_groups) {
        for (ModelVolume* vol : group->volumes) {
            vol->parent_group = group.get();
        }
    }
}
```

**Step 3:** Test thoroughly (1-2 hours)
```cpp
TEST_CASE("undo redo preserves groups") {
    // Setup
    Model model;
    ModelObject* obj = model.add_object();
    ModelVolume* vol1 = obj->add_volume(TriangleMesh());
    ModelVolume* vol2 = obj->add_volume(TriangleMesh());
    ModelVolumeGroup* group = obj->add_volume_group("TestGroup");
    obj->move_volume_to_group(vol1, group);
    obj->move_volume_to_group(vol2, group);

    // Serialize (undo snapshot)
    std::ostringstream os;
    {
        cereal::BinaryOutputArchive ar(os);
        ar(*obj);
    }

    // Modify (delete group)
    obj->delete_volume_group(group->id);
    REQUIRE(obj->volume_groups.empty());
    REQUIRE(vol1->parent_group == nullptr);

    // Deserialize (undo)
    std::istringstream is(os.str());
    {
        cereal::BinaryInputArchive ar(is);
        ModelObject obj2;
        ar(obj2);

        // Verify restoration
        REQUIRE(obj2.volume_groups.size() == 1);
        REQUIRE(obj2.volume_groups[0]->name == "TestGroup");
        REQUIRE(obj2.volume_groups[0]->volumes.size() == 2);
        REQUIRE(obj2.volumes[0]->parent_group == obj2.volume_groups[0].get());
        REQUIRE(obj2.volumes[1]->parent_group == obj2.volume_groups[0].get());
    }
}
```

**Validation:**
- ✅ Unit test passes
- ✅ Manual workflow: Create groups → Undo → Redo → Verify groups intact
- ✅ Save project → Load → Verify groups preserved

---

#### Task 2.2: Plate Presets Undo/Redo ⚠️ CRITICAL
**Feature:** #2 (Per-Plate Settings)
**Time:** 2 hours
**Files:** `src/slic3r/GUI/PartPlate.hpp:552-575`

**Implementation:**
```cpp
// PartPlate.hpp:552-575
template<class Archive> void save(Archive& ar) const {
    ar(m_plate_index, m_locked, m_ready_for_slice,
       m_slice_result_valid, m_print_index, m_plater_name,
       m_is_dark_color_plate,
       m_printer_preset_name,      // ✅ ADD THIS
       m_filament_preset_names);   // ✅ ADD THIS
}

template<class Archive> void load(Archive& ar) {
    ar(m_plate_index, m_locked, m_ready_for_slice,
       m_slice_result_valid, m_print_index, m_plater_name,
       m_is_dark_color_plate,
       m_printer_preset_name,      // ✅ ADD THIS
       m_filament_preset_names);   // ✅ ADD THIS
}
```

**Test:**
```cpp
TEST_CASE("undo redo preserves plate presets") {
    PartPlate plate;
    plate.set_printer_preset_name("Custom");
    plate.set_filament_preset_names({"PLA", "PETG"});

    // Serialize
    std::ostringstream os;
    {
        cereal::BinaryOutputArchive ar(os);
        plate.save(ar);
    }

    // Modify
    plate.set_printer_preset_name("Different");
    REQUIRE(plate.get_printer_preset_name() == "Different");

    // Deserialize
    std::istringstream is(os.str());
    {
        cereal::BinaryInputArchive ar(is);
        PartPlate plate2;
        plate2.load(ar);

        REQUIRE(plate2.get_printer_preset_name() == "Custom");
        REQUIRE(plate2.get_filament_preset_names().size() == 2);
    }
}
```

**Validation:**
- ✅ Test passes
- ✅ Manual: Set plate presets → Undo → Redo → Verify presets

---

#### Task 2.3: Add Explicit Undo Snapshots ⚠️ MEDIUM
**Features:** #2, #5
**Time:** 1 hour
**Files:** `src/slic3r/GUI/Plater.cpp`, `src/slic3r/GUI/GUI_ObjectList.cpp`

**Implementation:**
```cpp
// Plater.cpp - Add snapshot before plate preset changes
void Plater::priv::set_plate_printer_preset(int plate_idx, const std::string& name) {
    Plater::TakeSnapshot(
        wxGetApp().plater(),
        _(L("Change Plate Printer Preset")),
        UndoRedo::SnapshotType::PlateAction
    );

    PartPlate* plate = plate_list->get_plate(plate_idx);
    plate->set_printer_preset_name(name);
    update_background_process();
}

// GUI_ObjectList.cpp - Add snapshots for group operations
void ObjectList::add_volume_group() {
    Plater::TakeSnapshot(
        wxGetApp().plater(),
        _(L("Add Volume Group")),
        UndoRedo::SnapshotType::GizmoAction
    );

    // ... existing code ...
}

void ObjectList::delete_volume_group(int group_id) {
    Plater::TakeSnapshot(
        wxGetApp().plater(),
        _(L("Delete Volume Group")),
        UndoRedo::SnapshotType::GizmoAction
    );

    // ... existing code ...
}

void ObjectList::rename_volume_group(int group_id, const std::string& name) {
    Plater::TakeSnapshot(
        wxGetApp().plater(),
        _(L("Rename Volume Group")),
        UndoRedo::SnapshotType::GizmoAction
    );

    // ... existing code ...
}
```

**Validation:**
- ✅ Each operation creates undo stack entry
- ✅ Undo stack shows descriptive names

---

### Phase 2 Checkpoint
**Review Meeting:** After 6-7 hours
**Deliverables:**
- Undo/redo works for groups and plate presets
- All tests passing
- Manual testing complete

**Metrics:**
- Undo/redo success rate: 100%
- No data loss scenarios
- Undo stack descriptive

---

## Phase 3: Input Validation (Prevent Silent Failures)
**Duration:** 9 hours
**Risk Level:** 🟢 LOW
**Goal:** All configurations validated before use

### Tasks

#### Task 3.1: Flush Settings Validation ⚠️ HIGH
**Features:** #3, #4 (Multi-Material Flush)
**Time:** 4 hours
**Files:** `src/libslic3r/PrintConfig.cpp`, `src/slic3r/GUI/Tab.cpp`, `src/libslic3r/GCode/ToolOrdering.cpp`

**Step 1:** Add bounds checking to integer list parsing (1 hour)
```cpp
// PrintConfig.cpp - Create validation function
static std::string validate_filament_index_list(const ConfigOptionInts* opt, int max_extruders) {
    for (int val : opt->values) {
        if (val < 0) {
            return "Invalid filament index: " + std::to_string(val) + ". Must be >= 0.";
        }
        if (val >= max_extruders) {
            return "Invalid filament index: " + std::to_string(val) +
                   ". Maximum is " + std::to_string(max_extruders - 1) + ".";
        }
    }

    // Check duplicates
    std::set<int> unique_vals(opt->values.begin(), opt->values.end());
    if (unique_vals.size() != opt->values.size()) {
        return "Duplicate filament indices detected.";
    }

    return "";  // Valid
}

// Apply to each option
def = this->add("wipe_tower_filaments", coInts);
// ... existing setup ...
def->set_validator([](const ConfigOption* opt, const DynamicPrintConfig& config) -> std::string {
    auto* ints = static_cast<const ConfigOptionInts*>(opt);
    int max_extruders = config.option<ConfigOptionInt>("extruder_count")->value;
    return validate_filament_index_list(ints, max_extruders);
});
```

**Step 2:** Add "excluded from all targets" warning (2 hours)
```cpp
// Tab.cpp - Add validation on save
void TabPrint::on_presets_changed() {
    // ... existing code ...

    // ✅ ADD: Validate flush settings
    validate_flush_settings_completeness();
}

void TabPrint::validate_flush_settings_completeness() {
    auto* wipe_tower = m_config->option<ConfigOptionInts>("wipe_tower_filaments");
    auto* support = m_config->option<ConfigOptionInts>("support_flush_filaments");
    auto* infill = m_config->option<ConfigOptionInts>("infill_flush_filaments");
    int num_extruders = m_config->option<ConfigOptionInt>("extruder_count")->value;

    std::vector<int> excluded_filaments;

    for (int i = 0; i < num_extruders; i++) {
        bool in_tower = wipe_tower->values.empty() ||
                       std::find(wipe_tower->values.begin(),
                                wipe_tower->values.end(), i) != wipe_tower->values.end();
        bool in_support = support->values.empty() ||
                         std::find(support->values.begin(),
                                  support->values.end(), i) != support->values.end();
        bool in_infill = infill->values.empty() ||
                        std::find(infill->values.begin(),
                                 infill->values.end(), i) != infill->values.end();

        if (!in_tower && !in_support && !in_infill) {
            excluded_filaments.push_back(i);
        }
    }

    if (!excluded_filaments.empty()) {
        std::string message = "The following filaments are excluded from ALL flush targets "
                             "(prime tower, support, and infill):\n\n";
        for (int fid : excluded_filaments) {
            message += "  • Filament " + std::to_string(fid + 1) + "\n";
        }
        message += "\nTool changes involving these filaments will have INSUFFICIENT PURGING, "
                  "which may cause color contamination and print defects.\n\n"
                  "Enable at least one flush target for each filament.";

        wxMessageDialog dlg(this, message, _(L("Flush Settings Warning")),
                          wxOK | wxICON_WARNING);
        dlg.ShowModal();
    }
}
```

**Step 3:** Add G-code warnings (1 hour)
```cpp
// ToolOrdering.cpp:1770-1773
if (skip_tower_for_this_change && volume_to_purge > 0.f) {
    // Emit warning in G-code
    BOOST_LOG_TRIVIAL(warning) << "Filament " << new_extruder
        << " excluded from flush targets, remaining purge: " << volume_to_purge << "mm³";

    // Add to G-code comments
    // (This requires access to GCodeWriter, implementation depends on context)

    return 0.f;
}
```

**Validation:**
- ✅ Set invalid index (99) → Error on save
- ✅ Exclude filament from all targets → Warning dialog
- ✅ Slice with excluded filament → G-code warning comment

---

#### Task 3.2: Per-Plate + Flush Integration Validation ⚠️ HIGH
**Features:** #2 + #3/#4 Integration
**Time:** 3 hours
**Files:** `src/slic3r/GUI/PartPlate.cpp:2532`, `src/libslic3r/GCode/ToolOrdering.cpp:52`

**Step 1:** Add validation to plate settings (2 hours)
```cpp
// PartPlate.cpp:2532 - Extend validate_custom_presets()
bool PartPlate::validate_custom_presets(PresetBundle* preset_bundle, std::string* warning) const {
    // ... existing validation ...

    if (has_custom_printer_preset()) {
        int plate_extruder_count = printer_preset->config.option<ConfigOptionInt>("extruder_count")->value;
        const DynamicPrintConfig& project_config = preset_bundle->project_config;

        // ✅ ADD: Validate flush settings against plate extruder count
        auto check_flush_setting = [&](const char* setting_name) {
            if (project_config.has(setting_name)) {
                auto flush_filaments = project_config.option<ConfigOptionInts>(setting_name);
                for (int fid : flush_filaments->values) {
                    if (fid >= plate_extruder_count) {
                        warnings += boost::format(
                            "Global '%1%' setting references extruder %2%, "
                            "but this plate's printer only has %3% extruders. "
                            "This may cause slicing errors.\n"
                        ) % setting_name % (fid + 1) % plate_extruder_count;
                        has_warnings = true;
                    }
                }
            }
        };

        check_flush_setting("wipe_tower_filaments");
        check_flush_setting("support_flush_filaments");
        check_flush_setting("infill_flush_filaments");
    }

    // ... rest of function ...
}
```

**Step 2:** Add runtime filtering (1 hour)
```cpp
// ToolOrdering.cpp:52-61 - Update helper
static bool is_filament_allowed_for_flushing(
    const ConfigOptionInts& filament_list,
    unsigned int filament_id,
    unsigned int max_extruders = UINT_MAX)
{
    // Bounds check
    if (filament_id >= max_extruders) {
        BOOST_LOG_TRIVIAL(warning) << "Flush setting references extruder "
            << filament_id << " but only " << max_extruders << " available";
        return false;
    }

    // Empty = all allowed
    if (filament_list.empty())
        return true;

    return std::find(filament_list.values.begin(), filament_list.values.end(),
                    static_cast<int>(filament_id)) != filament_list.values.end();
}

// Update callsites to pass max_extruders
// Line 1626:
bool old_extruder_uses_tower = is_filament_allowed_for_flushing(
    print.config().wipe_tower_filaments, old_extruder, plate_extruder_count);
```

**Validation:**
- ✅ Plate with 2 extruders + global flush [0,1,2,3] → Warning in dialog
- ✅ Slicing proceeds without crash
- ✅ Out-of-range extruders filtered at runtime

---

#### Task 3.3: Missing Preset Warning ⚠️ MEDIUM
**Feature:** #2 (Per-Plate Settings)
**Time:** 2 hours
**Files:** `src/slic3r/GUI/PartPlate.cpp:2416`, `src/slic3r/GUI/Plater.cpp`

**Implementation:**
```cpp
// PartPlate.cpp:2416 - Add warning when fallback occurs
const Preset* preset = preset_bundle->filaments.find_preset(filament_name);
if (!preset) {
    // Preset not found - warn user
    BOOST_LOG_TRIVIAL(warning) << "Plate " << m_plate_index
        << " references missing filament preset: " << filament_name;

    // ✅ ADD: Show notification
    wxGetApp().plater()->get_notification_manager()->push_notification(
        NotificationType::CustomNotification,
        NotificationManager::NotificationLevel::WarningNotificationLevel,
        "Missing Filament Preset",
        "Plate " + std::to_string(m_plate_index + 1) +
        " references filament preset '" + filament_name +
        "' which no longer exists. Using default preset instead."
    );

    preset = &preset_bundle->filaments.first_visible();
}
```

**Validation:**
- ✅ Load 3MF with deleted preset → Notification shown
- ✅ User aware of missing preset

---

### Phase 3 Checkpoint
**Review Meeting:** After 9 hours
**Deliverables:**
- All input validation in place
- Warnings for invalid configurations
- Runtime safety checks

**Metrics:**
- No silent failures
- Clear error messages
- Graceful fallbacks

---

## Phase 4: User Experience Fixes (Meet Expectations)
**Duration:** 8 hours
**Risk Level:** 🟡 MEDIUM
**Goal:** Features behave as users expect

### Tasks

#### Task 4.1: Fix Width/Height Semantics ⚠️ MEDIUM
**Feature:** #6 (Cutting Plane)
**Time:** 4 hours
**Files:** `src/slic3r/GUI/Gizmos/GLGizmoCut.cpp:1840-1849`, `src/libslic3r/TriangleMesh.cpp`

**Step 1:** Implement rectangular plane generation (2 hours)
```cpp
// TriangleMesh.cpp - Add new function
indexed_triangle_set its_make_rectangle_plane(double width, double height, double thickness) {
    indexed_triangle_set mesh;

    double hw = width / 2.0;
    double hh = height / 2.0;
    double ht = thickness / 2.0;

    // 8 vertices (rectangular box)
    mesh.vertices = {
        {-hw, -hh, -ht}, {hw, -hh, -ht}, {hw, hh, -ht}, {-hw, hh, -ht},  // Bottom
        {-hw, -hh, ht},  {hw, -hh, ht},  {hw, hh, ht},  {-hw, hh, ht}   // Top
    };

    // 12 triangles (2 per face)
    mesh.indices = {
        {0, 1, 2}, {0, 2, 3},  // Bottom
        {4, 6, 5}, {4, 7, 6},  // Top
        {0, 4, 5}, {0, 5, 1},  // Front
        {1, 5, 6}, {1, 6, 2},  // Right
        {2, 6, 7}, {2, 7, 3},  // Back
        {3, 7, 4}, {3, 4, 0}   // Left
    };

    return mesh;
}
```

**Step 2:** Update cutting gizmo to use rectangle (1 hour)
```cpp
// GLGizmoCut.cpp:1840-1849
if (!m_auto_size_plane && m_plane_width > 0.f && m_plane_height > 0.f) {
    // ✅ CHANGE: Use rectangular plane
    indexed_triangle_set its = its_make_rectangle_plane(
        m_plane_width,   // Actual width
        m_plane_height,  // Actual height
        cp_width
    );
} else {
    // Auto-size: square plane
    double plane_radius = (double)m_cut_plane_radius_koef * m_radius;
    indexed_triangle_set its = its_make_frustum_dowel(plane_radius, cp_width, 4);
}
```

**Step 3:** Add validation on load (30 minutes)
```cpp
// GLGizmoCut.cpp:1252
void on_load(cereal::BinaryInputArchive& ar) override {
    ar(m_plane_width, m_plane_height, m_auto_size_plane);

    // ✅ ADD: Clamp to valid range
    m_plane_width = std::clamp(m_plane_width, 10.f, 500.f);
    m_plane_height = std::clamp(m_plane_height, 10.f, 500.f);
}
```

**Step 4:** Test (30 minutes)
```cpp
TEST_CASE("manual plane creates rectangle") {
    GLGizmoCut3D gizmo;
    gizmo.set_auto_size_plane(false);
    gizmo.set_plane_dimensions(100.f, 200.f);

    indexed_triangle_set its = gizmo.get_plane_mesh();

    // Calculate bounding box
    BoundingBoxf3 bbox;
    for (const Vec3f& v : its.vertices) {
        bbox.merge(v.cast<double>());
    }

    // Verify dimensions
    REQUIRE(bbox.size().x() == Approx(100.0).margin(1.0));
    REQUIRE(bbox.size().y() == Approx(200.0).margin(1.0));
}
```

**Validation:**
- ✅ Set width=100, height=200 → Plane is 100×200mm rectangle
- ✅ Test passes
- ✅ Manual verification with measurement

---

#### Task 4.2: Duplicate Plate Copies Presets ⚠️ LOW
**Feature:** #2 (Per-Plate Settings)
**Time:** 1 hour
**Files:** `src/slic3r/GUI/PartPlate.cpp:4482-4510`

**Implementation:**
```cpp
// PartPlate.cpp:4489 - After creating new plate
new_plate = get_plate(new_plate_index);

// ✅ ADD: Copy preset settings
new_plate->set_printer_preset_name(old_plate->get_printer_preset_name());
new_plate->set_filament_preset_names(old_plate->get_filament_preset_names());
```

**Validation:**
- ✅ Set plate presets → Duplicate plate → New plate has same presets

---

#### Task 4.3: Preserve Groups Through Cutting ⚠️ MEDIUM
**Features:** #5 + #6 Integration
**Time:** 3 hours
**Files:** `src/slic3r/GUI/Gizmos/GLGizmoCut.cpp:3377-3414`

**Implementation:**
```cpp
// GLGizmoCut.cpp:3377 - Before performing cut
// ✅ ADD: Collect group info
std::map<int, std::pair<std::string, int>> volume_to_group_info;
for (size_t i = 0; i < mo->volumes.size(); i++) {
    ModelVolume* vol = mo->volumes[i].get();
    if (vol->get_parent_group()) {
        ModelVolumeGroup* group = vol->get_parent_group();
        volume_to_group_info[i] = {group->name, group->extruder_id};
    }
}

// ... perform cut ...

// GLGizmoCut.cpp:3414 - After cut creates new objects
// ✅ ADD: Recreate groups in new objects
for (ModelObject* new_obj : new_objects) {
    // For each volume in new object, check if it came from a grouped volume
    // (This requires tracking which volumes came from which original volumes)

    std::map<std::string, ModelVolumeGroup*> created_groups;

    for (size_t i = 0; i < new_obj->volumes.size(); i++) {
        // Determine if this volume came from a grouped volume
        // (Implementation depends on how cut tracking works)

        int original_volume_idx = /* get original volume index */;
        if (volume_to_group_info.count(original_volume_idx)) {
            auto [group_name, extruder_id] = volume_to_group_info[original_volume_idx];

            // Create or reuse group
            ModelVolumeGroup* group;
            if (!created_groups.count(group_name)) {
                group = new_obj->add_volume_group(group_name);
                group->extruder_id = extruder_id;
                created_groups[group_name] = group;
            } else {
                group = created_groups[group_name];
            }

            // Add volume to group
            new_obj->move_volume_to_group(new_obj->volumes[i].get(), group);
        }
    }
}
```

**Alternative (simpler):** Show warning dialog
```cpp
// GLGizmoCut.cpp:3370 - Before cut
if (/* volume is in a group */) {
    wxMessageDialog dlg(
        nullptr,
        "Volume is part of group '" + group_name + "'. "
        "Cut pieces will be ungrouped. Continue?",
        "Cut Grouped Volume",
        wxYES_NO | wxICON_QUESTION
    );

    if (dlg.ShowModal() != wxID_YES) {
        return;  // Cancel cut
    }
}
```

**Validation:**
- ✅ Cut grouped volume → Warning shown or groups preserved
- ✅ User aware of consequences

---

### Phase 4 Checkpoint
**Review Meeting:** After 8 hours
**Deliverables:**
- Cutting plane creates true rectangles
- Duplicate plate copies presets
- Group cutting handled gracefully

**User Testing:**
- ✅ 5 users test workflows
- ✅ Collect feedback
- ✅ No confusion about behavior

---

## Phase 5: Production Hardening (Testing & Polish)
**Duration:** 22 hours
**Risk Level:** 🟢 LOW
**Goal:** Production-ready with comprehensive test coverage

### Tasks

#### Task 5.1: Unit Test Suite ⚠️ MEDIUM
**All Features**
**Time:** 12 hours
**Files:** `tests/libslic3r/`, `tests/slic3r/`

**Test Categories:**

**Feature #2 Tests (6 tests, 3 hours):**
```cpp
// tests/slic3r/test_per_plate_settings.cpp
TEST_CASE("build_plate_config_with_custom_presets")
TEST_CASE("build_plate_config_fallback_to_global")
TEST_CASE("validate_missing_printer_preset")
TEST_CASE("validate_missing_filament_preset")
TEST_CASE("validate_extruder_count_mismatch")
TEST_CASE("duplicate_plate_copies_presets")
```

**Feature #5 Tests (5 tests, 3 hours):**
```cpp
// tests/libslic3r/test_volume_groups.cpp
TEST_CASE("delete_volume_removes_from_group")
TEST_CASE("undo_redo_preserves_groups")
TEST_CASE("copy_object_preserves_groups")
TEST_CASE("clear_volumes_cleans_groups")
TEST_CASE("add_duplicate_group_name")
```

**Feature #3/#4 Tests (4 tests, 2 hours):**
```cpp
// tests/libslic3r/test_flush_settings.cpp
TEST_CASE("filament_excluded_from_all_targets")
TEST_CASE("invalid_filament_index_ignored")
TEST_CASE("out_of_range_extruder_filtered")
TEST_CASE("parse_malformed_integer_list")
```

**Feature #6 Tests (3 tests, 2 hours):**
```cpp
// tests/slic3r/test_cutting_plane.cpp
TEST_CASE("manual_size_creates_correct_dimensions")
TEST_CASE("deserialized_values_clamped")
TEST_CASE("auto_size_with_hollow_model")
```

**Integration Tests (5 tests, 2 hours):**
```cpp
// tests/integration/test_feature_integration.cpp
TEST_CASE("per_plate_with_flush_settings_validation")
TEST_CASE("group_extruder_vs_plate_printer")
TEST_CASE("cut_grouped_volume_preserves_groups")
TEST_CASE("save_load_all_features_roundtrip")
TEST_CASE("multi_plate_different_extruder_counts")
```

**Execution:**
- Write tests incrementally
- Run after each batch
- Target: >90% code coverage for new features

---

#### Task 5.2: Integration Testing ⚠️ HIGH
**All Features**
**Time:** 6 hours
**Files:** Test scripts + manual procedures

**Scenario A: Multi-Plate Workflow (2 hours)**
```
Setup:
1. Create project with 3 plates
2. Plate 1: X1C (4 extruders), custom filaments
3. Plate 2: P1S (2 extruders), custom filaments
4. Plate 3: Default printer
5. Set global flush settings [0,1,2,3]
6. Create groups on each plate

Test Flow:
1. Verify warnings on Plate 2 (extruder mismatch)
2. Slice each plate successfully
3. Cut grouped volume → verify groups
4. Undo/redo all operations → verify state
5. Save and reload project → verify persistence

Expected Results:
- All operations succeed
- Warnings appropriate
- No crashes or data loss
```

**Scenario B: Group Lifecycle (2 hours)**
```
Test Flow:
1. Create object with 3 volumes
2. Create group "Parts"
3. Add all volumes to group
4. Duplicate object → verify groups copied
5. Delete one volume → verify group updated
6. Undo delete → verify group restored
7. Cut one volume → verify group handling
8. Save → Load → verify groups persist

Expected Results:
- Groups maintained throughout
- Undo/redo works correctly
- Save/load preserves state
```

**Scenario C: Extreme Configurations (2 hours)**
```
Test Flow:
1. 16-extruder printer (max supported)
2. All 16 filaments with custom settings
3. Flush settings with all indices
4. 50 groups with 100 volumes each
5. 10 plates with different printers
6. Save (check file size)
7. Load (check performance)

Expected Results:
- No crashes
- Reasonable performance
- Accurate behavior
```

---

#### Task 5.3: Documentation & Code Comments ⚠️ LOW
**All Features**
**Time:** 6 hours
**Files:** All modified files

**Developer Documentation (3 hours):**
```cpp
/**
 * @brief Deletes a volume from the ModelObject
 *
 * This function removes a volume and cleans up any associated group memberships.
 * If the volume belongs to a group and is the last member, the group is also deleted.
 *
 * @param idx Zero-based index of the volume to delete
 *
 * @note This operation is undoable if called within a TakeSnapshot context
 * @warning Caller must ensure idx is valid (0 <= idx < volumes.size())
 *
 * @see add_volume(), move_volume_to_group()
 */
void ModelObject::delete_volume(size_t idx);
```

**User Documentation (2 hours):**
- Update wiki pages
- Add screenshots
- Write tutorials

**API Documentation (1 hour):**
- Update Doxygen comments
- Generate API docs

---

#### Task 5.4: Performance Profiling ⚠️ LOW
**All Features**
**Time:** 4 hours
**Tools:** Profiler, benchmarks

**Profile Points:**
1. Undo/redo with 100 groups (target: <100ms)
2. Validate 10 plates with flush settings (target: <50ms)
3. Load 3MF with 1000 volumes in groups (target: <2s)
4. Slice 10 plates sequentially (target: no regression)

**Optimization:**
- If any operation >2x target, optimize
- Document performance characteristics

---

### Phase 5 Checkpoint
**Review Meeting:** After 22 hours
**Deliverables:**
- 23 unit tests (all passing)
- 3 integration scenarios (all passing)
- Documentation complete
- Performance profiled

**Metrics:**
- Code coverage: >90% for new features
- Test pass rate: 100%
- Performance: Within targets
- Documentation: Complete

---

## Final Release Checklist

### Code Quality
- [ ] All P0/P1 gaps fixed
- [ ] No compiler warnings
- [ ] No memory leaks (Valgrind/ASAN clean)
- [ ] No TODO/FIXME in critical paths

### Testing
- [ ] 23 unit tests pass
- [ ] 3 integration scenarios pass
- [ ] Manual testing complete (10 workflows)
- [ ] Regression tests pass (existing features)

### Documentation
- [ ] Code comments added
- [ ] API docs generated
- [ ] User guide updated
- [ ] Release notes written

### Performance
- [ ] No performance regressions
- [ ] All operations within targets
- [ ] Memory usage acceptable
- [ ] File size reasonable (<2× increase)

### Integration
- [ ] Builds on all platforms (Windows/macOS/Linux)
- [ ] No conflicts with main branch
- [ ] CI/CD passes
- [ ] Ready for merge

---

## Risk Mitigation

### High-Risk Areas

**Serialization Changes (Phase 2):**
- **Risk:** Breaking undo/redo for all features
- **Mitigation:**
  - Test with 1000+ undo/redo cycles
  - Backup tests before/after
  - Rollback plan ready

**Rectangular Plane (Phase 4):**
- **Risk:** Breaking cut operation
- **Mitigation:**
  - Extensive manual testing
  - Keep old code path as fallback
  - Feature flag if needed

**Integration Validation (Phase 3):**
- **Risk:** False positives annoying users
- **Mitigation:**
  - User testing feedback
  - Adjust warning thresholds
  - Make warnings dismissible

### Rollback Plan

If critical issue found after any phase:
1. **Revert changes** via git
2. **Fix in isolation** with new test
3. **Re-integrate** when stable
4. **Document lesson** in postmortem

---

## Success Metrics

### By Phase

| Phase | Duration | Tests Passing | Bugs Fixed | Risk Reduction |
|-------|----------|---------------|------------|----------------|
| 1 | 2h | 3 | 3 crashes | 60% |
| 2 | 7h | 5 | 2 critical | 80% |
| 3 | 9h | 9 | 5 validation | 90% |
| 4 | 8h | 3 | 3 UX | 95% |
| 5 | 22h | 23 | Polish | 99% |
| **Total** | **48h** | **43** | **13+** | **99%** |

### Final Metrics

**Code Quality:**
- Coverage: 90%+ for new features
- Complexity: All functions <50 lines
- Documentation: 100% public APIs

**Stability:**
- Zero known crashes
- Zero data loss scenarios
- Graceful degradation everywhere

**User Experience:**
- Clear error messages
- Intuitive behavior
- No surprises

---

## Timeline Visualization

```
Week 1: Critical Fixes + Undo/Redo
├─ Day 1: Phase 1 (2h) → Phase 2 start (4h)
├─ Day 2: Phase 2 complete (3h)
└─ Day 3: Phase 3 start (3h)

Week 2: Validation + UX
├─ Day 4: Phase 3 continue (6h)
├─ Day 5: Phase 4 start (6h)
└─ Day 6: Phase 4 complete (2h)

Week 3-4: Testing & Polish
├─ Week 3: Phase 5 testing (16h)
└─ Week 4: Phase 5 docs/perf (6h) → Final review

Total: 4 weeks (48 hours development time)
```

---

## Iteration & Feedback Loops

### After Each Phase
1. **Review meeting** (30 min)
2. **Demo to stakeholders** (15 min)
3. **Collect feedback** (user testing if applicable)
4. **Adjust next phase** based on findings
5. **Document lessons learned**

### Continuous Improvement
- **Daily:** Run test suite
- **Weekly:** Review code coverage
- **Bi-weekly:** User feedback session
- **Monthly:** Refactoring review

---

## Conclusion

This plan addresses all 47 identified gaps through 5 iterative phases with testing and validation at every step. The recursive approach ensures each phase builds on a solid foundation, with clear success criteria and rollback plans.

**Total Investment:** 48 hours development time
**Expected Outcome:** Production-ready implementation
**Risk Level:** LOW (with proper execution)
**Confidence:** HIGH (all gaps have clear solutions)

The features are functionally complete. With this plan executed, they will be production-grade with enterprise-level quality.

---

**Next Steps:**
1. Review and approve this plan
2. Begin Phase 1 implementation
3. Execute with discipline and testing rigor
4. Ship production-ready features

🚀 **Ready to implement!**
