# Feature #2 Implementation Plan: Per-Plate Printer/Filament Settings

**Status:** 📋 Detailed Implementation Plan
**Estimated Time:** 7-10 hours
**Complexity:** High (Most Complex Feature)

---

## Overview

Allow different printer and filament configurations per plate within a single project. This enables multi-printer workflows, material variations across plates, and complex print queues without managing separate projects.

**Key Benefits:**
- Test different settings on different plates
- Multi-printer workflows (same model, different printers)
- Material variations (Plate 1: PLA, Plate 2: PETG)
- Complex print queues with different configurations

---

## Architecture Design

### Data Model Extension

```
PlateData (existing struct)
├── plate_index (int)
├── objects_and_instances (vector)
├── gcode_file (string)
├── ... (existing fields)
├── printer_preset_name (string) ← NEW (empty = use global)
└── filament_preset_names (vector<string>) ← NEW (empty = use global)

Print
├── m_config (DynamicPrintConfig) ← Global config
└── New: resolve_config_for_plate(int plate_idx) → DynamicPrintConfig
```

**Config Resolution Flow:**
```
Global Config
    ↓
+ Plate Printer Preset (if specified)
    ↓
+ Plate Filament Presets (if specified)
    ↓
= Resolved Config for Plate
```

---

## Phased Implementation Strategy

Given complexity, implement in 3 sub-phases:

**Phase 1:** Per-plate printer selection (simpler)
**Phase 2:** Per-plate filament selection
**Phase 3:** Background slicing integration

---

## Phase 1: Per-Plate Printer Selection

### Step 1.1: Extend PlateData Structure

**File:** `src/libslic3r/PartPlate.hpp`
**In PlateData struct (around line 52):**

Add members:
```cpp
// Orca: Per-plate printer preset
std::string printer_preset_name;  // Empty = use global printer

// Check if this plate has custom printer
bool has_custom_printer() const {
    return !printer_preset_name.empty();
}

// Get effective printer preset name
std::string get_effective_printer_preset(const std::string& global_preset) const {
    return has_custom_printer() ? printer_preset_name : global_preset;
}
```

---

### Step 1.2: Per-Plate Config Resolution

**File:** `src/libslic3r/Print.hpp`
**In Print class:**

Add methods:
```cpp
// Resolve configuration for a specific plate
DynamicPrintConfig resolve_config_for_plate(int plate_idx) const;

// Apply plate-specific config before slicing
void apply_plate_config(int plate_idx);

// Get plate data
const PlateData* get_plate_data(int plate_idx) const;
```

**Implementation:** `src/libslic3r/Print.cpp`

```cpp
DynamicPrintConfig Print::resolve_config_for_plate(int plate_idx) const
{
    // Start with global config
    DynamicPrintConfig plate_config = m_config;

    // Get plate data
    const PlateData* plate = get_plate_data(plate_idx);
    if (!plate)
        return plate_config;

    // If plate has custom printer, merge printer preset
    if (plate->has_custom_printer()) {
        // Load printer preset by name
        const Preset* printer_preset = m_preset_bundle->printers.find_preset(
            plate->printer_preset_name,
            false  // don't throw if not found
        );

        if (printer_preset && printer_preset->is_visible) {
            // Merge printer config into plate config
            // Printer settings override global
            plate_config.apply(printer_preset->config, true);
        }
    }

    return plate_config;
}

void Print::apply_plate_config(int plate_idx)
{
    DynamicPrintConfig plate_config = resolve_config_for_plate(plate_idx);

    // Apply to print config
    // NOTE: This temporarily modifies m_config
    // Must be restored after slicing this plate
    m_config = plate_config;

    // Invalidate affected steps
    invalidate_all_steps();
}
```

---

### Step 1.3: 3MF Serialization (Printer)

**File:** `src/libslic3r/Format/bbs_3mf.cpp`

**Export (in `_add_slice_info_config_file_to_archive`, around line 7866):**

```cpp
// Orca: Export per-plate printer preset
if (plate_data->has_custom_printer()) {
    stream << "    <" << METADATA_TAG << " " << KEY_ATTR << "=\""
           << "printer_preset\" " << VALUE_ATTR << "=\""
           << xml_escape(plate_data->printer_preset_name) << "\"/>\n";
}
```

**Import (in `_handle_start_config_metadata`, around line 4250):**

```cpp
else if (key == "printer_preset") {
    if (m_curr_plater) {
        m_curr_plater->printer_preset_name = value;
    }
}
```

Add constant:
```cpp
static constexpr const char* PRINTER_PRESET_ATTR = "printer_preset";
```

---

### Step 1.4: GUI - Plate Settings Panel

**File:** `src/slic3r/GUI/Plater.hpp`
**In Plater::priv class:**

```cpp
// Orca: Per-plate settings dialog
void show_plate_settings_dialog(int plate_idx);

// UI elements
wxChoice* m_plate_printer_choice{nullptr};
```

**File:** `src/slic3r/GUI/Plater.cpp`

```cpp
void Plater::priv::show_plate_settings_dialog(int plate_idx)
{
    PlateData* plate = partplate_list.get_plate(plate_idx);
    if (!plate)
        return;

    wxDialog dlg(q, wxID_ANY, _L("Plate Settings"),
                 wxDefaultPosition, wxSize(400, 300));

    wxBoxSizer* main_sizer = new wxBoxSizer(wxVERTICAL);

    // Plate name
    wxStaticText* name_label = new wxStaticText(&dlg, wxID_ANY,
        wxString::Format(_L("Settings for: %s"), plate->plate_name));
    main_sizer->Add(name_label, 0, wxALL, 10);

    main_sizer->AddSpacer(10);

    // Custom printer checkbox
    wxCheckBox* custom_printer_check = new wxCheckBox(&dlg, wxID_ANY,
        _L("Use custom printer for this plate"));
    custom_printer_check->SetValue(plate->has_custom_printer());
    main_sizer->Add(custom_printer_check, 0, wxALL | wxEXPAND, 5);

    // Printer selection
    wxBoxSizer* printer_sizer = new wxBoxSizer(wxHORIZONTAL);
    wxStaticText* printer_label = new wxStaticText(&dlg, wxID_ANY, _L("Printer:"));
    printer_sizer->Add(printer_label, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 5);

    wxChoice* printer_choice = new wxChoice(&dlg, wxID_ANY);

    // Populate with compatible printers
    const std::string& global_printer = preset_bundle->printers.get_selected_preset_name();
    int selection_idx = 0;

    printer_choice->Append(wxString::Format(_L("Global (%s)"), global_printer));

    const PresetCollection& printers = preset_bundle->printers;
    for (size_t i = 0; i < printers.size(); ++i) {
        const Preset& preset = printers.preset(i);
        if (!preset.is_visible || preset.is_external)
            continue;

        // TODO: Filter by compatibility with current print preset
        printer_choice->Append(preset.name);

        if (plate->has_custom_printer() &&
            preset.name == plate->printer_preset_name) {
            selection_idx = printer_choice->GetCount() - 1;
        }
    }

    printer_choice->SetSelection(selection_idx);
    printer_choice->Enable(plate->has_custom_printer());
    printer_sizer->Add(printer_choice, 1, wxEXPAND);
    main_sizer->Add(printer_sizer, 0, wxALL | wxEXPAND, 5);

    // Bind events
    custom_printer_check->Bind(wxEVT_CHECKBOX, [printer_choice](wxCommandEvent& e) {
        printer_choice->Enable(e.IsChecked());
    });

    main_sizer->AddSpacer(10);

    // Validation warnings
    wxStaticText* warning_label = new wxStaticText(&dlg, wxID_ANY, "");
    warning_label->SetForegroundColour(*wxRED);
    main_sizer->Add(warning_label, 0, wxALL | wxEXPAND, 5);

    // OK/Cancel buttons
    wxStdDialogButtonSizer* buttons = new wxStdDialogButtonSizer();
    wxButton* ok_btn = new wxButton(&dlg, wxID_OK);
    wxButton* cancel_btn = new wxButton(&dlg, wxID_CANCEL);
    buttons->AddButton(ok_btn);
    buttons->AddButton(cancel_btn);
    buttons->Realize();
    main_sizer->Add(buttons, 0, wxALL | wxEXPAND, 10);

    dlg.SetSizer(main_sizer);
    dlg.Fit();

    if (dlg.ShowModal() == wxID_OK) {
        // Apply settings
        if (custom_printer_check->GetValue()) {
            int sel = printer_choice->GetSelection();
            if (sel > 0) {  // 0 = "Global"
                plate->printer_preset_name = printer_choice->GetString(sel).ToStdString();
            }
        } else {
            plate->printer_preset_name.clear();
        }

        // Validate and re-slice plate
        validate_plate_settings(plate_idx);
        reslice_plate(plate_idx);
    }
}

void Plater::priv::validate_plate_settings(int plate_idx)
{
    PlateData* plate = partplate_list.get_plate(plate_idx);
    if (!plate || !plate->has_custom_printer())
        return;

    // Load printer preset
    const Preset* printer_preset = preset_bundle->printers.find_preset(
        plate->printer_preset_name, false
    );
    if (!printer_preset)
        return;

    // Check bed size compatibility
    BoundingBoxf plate_bb = get_plate_bounding_box(plate_idx);
    Vec2d bed_size = get_bed_size_from_preset(*printer_preset);

    if (plate_bb.max.x() > bed_size.x() || plate_bb.max.y() > bed_size.y()) {
        wxMessageBox(
            _L("Warning: Objects on this plate may exceed the selected printer's bed size!"),
            _L("Plate Settings"),
            wxOK | wxICON_WARNING
        );
    }

    // Check filament count compatibility
    // TODO: Add when implementing Phase 2 (per-plate filaments)
}
```

---

### Step 1.5: Plate List Visual Indicator

**File:** `src/slic3r/GUI/PartPlateList.cpp`

```cpp
void PartPlateList::render_plate_item(wxDC& dc, const PlateData* plate, wxRect rect)
{
    // ... existing render code ...

    // Orca: Show indicator if plate has custom settings
    if (plate->has_custom_printer()) {
        // Draw badge/icon
        wxBitmap badge = create_scaled_bitmap("settings_badge");
        dc.DrawBitmap(badge, rect.GetRight() - 20, rect.GetTop() + 5);

        // Or draw text indicator
        dc.SetTextForeground(*wxBLUE);
        dc.SetFont(dc.GetFont().Smaller());
        dc.DrawText("⚙", rect.GetRight() - 15, rect.GetTop() + 2);
    }
}

wxString PartPlateList::get_plate_tooltip(const PlateData* plate)
{
    wxString tooltip = wxString::Format("Plate %d: %s\n",
        plate->plate_index + 1,
        plate->plate_name);

    if (plate->has_custom_printer()) {
        tooltip += wxString::Format(_L("\nPrinter: %s"), plate->printer_preset_name);
    }

    // Add more info...
    return tooltip;
}
```

---

### Step 1.6: Menu Integration

**File:** `src/slic3r/GUI/Plater.cpp`

Add menu item:
```cpp
void Plater::on_plate_right_click(wxContextMenuEvent& event)
{
    wxMenu menu;

    // ... existing menu items ...

    menu.AppendSeparator();

    append_menu_item(&menu, wxID_ANY, _L("Plate settings..."), "",
        [this](wxCommandEvent&) {
            p->show_plate_settings_dialog(p->partplate_list.get_current_plate());
        }, "settings");

    PopupMenu(&menu);
}
```

---

## Phase 2: Per-Plate Filament Selection

### Step 2.1: Extend PlateData for Filaments

**File:** `src/libslic3r/PartPlate.hpp`

```cpp
// Orca: Per-plate filament presets
std::vector<std::string> filament_preset_names;  // Empty = use global filaments

bool has_custom_filaments() const {
    return !filament_preset_names.empty();
}

std::vector<std::string> get_effective_filament_presets(
    const std::vector<std::string>& global_presets) const
{
    return has_custom_filaments() ? filament_preset_names : global_presets;
}

// Validate filament count matches printer
bool validate_filament_count(int expected_count) const {
    if (!has_custom_filaments())
        return true;
    return filament_preset_names.size() == expected_count;
}
```

---

### Step 2.2: Config Resolution with Filaments

**File:** `src/libslic3r/Print.cpp`

Extend `resolve_config_for_plate()`:
```cpp
DynamicPrintConfig Print::resolve_config_for_plate(int plate_idx) const
{
    DynamicPrintConfig plate_config = m_config;
    const PlateData* plate = get_plate_data(plate_idx);
    if (!plate)
        return plate_config;

    // Apply custom printer preset
    if (plate->has_custom_printer()) {
        const Preset* printer_preset = m_preset_bundle->printers.find_preset(
            plate->printer_preset_name, false
        );
        if (printer_preset && printer_preset->is_visible) {
            plate_config.apply(printer_preset->config, true);
        }
    }

    // Orca: Apply custom filament presets
    if (plate->has_custom_filaments()) {
        // Get number of extruders
        int extruder_count = plate_config.option<ConfigOptionFloats>("nozzle_diameter")->size();

        // Validate filament count
        if (!plate->validate_filament_count(extruder_count)) {
            BOOST_LOG_TRIVIAL(warning) << "Plate " << plate_idx
                << ": Filament count mismatch (expected "
                << extruder_count << ", got "
                << plate->filament_preset_names.size() << ")";
            // Fall back to global filaments
            return plate_config;
        }

        // Merge each filament preset
        for (size_t i = 0; i < plate->filament_preset_names.size(); ++i) {
            const Preset* filament_preset = m_preset_bundle->filaments.find_preset(
                plate->filament_preset_names[i], false
            );

            if (filament_preset && filament_preset->is_visible) {
                // Apply filament config for extruder i
                // This is more complex because filament settings are per-extruder
                apply_filament_preset_to_extruder(plate_config, *filament_preset, i);
            }
        }
    }

    return plate_config;
}

void Print::apply_filament_preset_to_extruder(
    DynamicPrintConfig& target_config,
    const Preset& filament_preset,
    size_t extruder_idx) const
{
    // Iterate through all filament-specific options
    for (const auto& opt_key : filament_preset.config.keys()) {
        const ConfigOption* src_opt = filament_preset.config.option(opt_key);
        ConfigOption* dst_opt = target_config.option(opt_key, false);

        if (!src_opt || !dst_opt)
            continue;

        // If it's a vector option, update only the index for this extruder
        if (auto* src_vec = dynamic_cast<const ConfigOptionVectorBase*>(src_opt)) {
            if (auto* dst_vec = dynamic_cast<ConfigOptionVectorBase*>(dst_opt)) {
                if (extruder_idx < dst_vec->size() && extruder_idx < src_vec->size()) {
                    dst_vec->set_at(src_vec, extruder_idx, extruder_idx);
                }
            }
        } else {
            // Scalar option, just copy
            dst_opt->set(src_opt);
        }
    }
}
```

---

### Step 2.3: 3MF Serialization (Filaments)

**File:** `src/libslic3r/Format/bbs_3mf.cpp`

**Export:**
```cpp
// Orca: Export per-plate filament presets
if (plate_data->has_custom_filaments()) {
    stream << "    <" << METADATA_TAG << " " << KEY_ATTR << "=\""
           << "filament_presets\" " << VALUE_ATTR << "=\"";

    // Comma-separated filament names
    for (size_t i = 0; i < plate_data->filament_preset_names.size(); ++i) {
        if (i > 0) stream << ",";
        stream << xml_escape(plate_data->filament_preset_names[i]);
    }

    stream << "\"/>\n";
}
```

**Import:**
```cpp
else if (key == "filament_presets") {
    if (m_curr_plater) {
        // Split comma-separated string
        std::vector<std::string> filaments;
        std::stringstream ss(value);
        std::string item;
        while (std::getline(ss, item, ',')) {
            filaments.push_back(item);
        }
        m_curr_plater->filament_preset_names = filaments;
    }
}
```

---

### Step 2.4: GUI - Filament Selection

**File:** `src/slic3r/GUI/Plater.cpp`

Extend `show_plate_settings_dialog()`:

```cpp
// Add after printer selection:

main_sizer->AddSpacer(10);

// Custom filaments checkbox
wxCheckBox* custom_filaments_check = new wxCheckBox(&dlg, wxID_ANY,
    _L("Use custom filaments for this plate"));
custom_filaments_check->SetValue(plate->has_custom_filaments());
main_sizer->Add(custom_filaments_check, 0, wxALL | wxEXPAND, 5);

// Filament selection (one per extruder)
int extruder_count = get_extruder_count_for_plate(plate_idx);
std::vector<wxChoice*> filament_choices;

for (int i = 0; i < extruder_count; ++i) {
    wxBoxSizer* fil_sizer = new wxBoxSizer(wxHORIZONTAL);
    wxStaticText* fil_label = new wxStaticText(&dlg, wxID_ANY,
        wxString::Format(_L("Filament %d:"), i + 1));
    fil_sizer->Add(fil_label, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 5);

    wxChoice* fil_choice = new wxChoice(&dlg, wxID_ANY);

    // Populate with compatible filaments
    const std::string& global_fil = preset_bundle->filament_presets[i];
    fil_choice->Append(wxString::Format(_L("Global (%s)"), global_fil));

    const PresetCollection& filaments = preset_bundle->filaments;
    for (size_t j = 0; j < filaments.size(); ++j) {
        const Preset& preset = filaments.preset(j);
        if (!preset.is_visible || preset.is_external)
            continue;

        // TODO: Filter by printer compatibility
        fil_choice->Append(preset.name);
    }

    // Set current selection
    if (plate->has_custom_filaments() && i < plate->filament_preset_names.size()) {
        int sel_idx = fil_choice->FindString(plate->filament_preset_names[i]);
        if (sel_idx != wxNOT_FOUND)
            fil_choice->SetSelection(sel_idx);
    } else {
        fil_choice->SetSelection(0);  // Global
    }

    fil_choice->Enable(plate->has_custom_filaments());
    fil_sizer->Add(fil_choice, 1, wxEXPAND);
    main_sizer->Add(fil_sizer, 0, wxALL | wxEXPAND, 5);

    filament_choices.push_back(fil_choice);
}

// Bind checkbox to enable/disable filament choices
custom_filaments_check->Bind(wxEVT_CHECKBOX, [filament_choices](wxCommandEvent& e) {
    bool enabled = e.IsChecked();
    for (auto* choice : filament_choices) {
        choice->Enable(enabled);
    }
});

// In OK button handler, save filament selections:
if (custom_filaments_check->GetValue()) {
    plate->filament_preset_names.clear();
    for (auto* choice : filament_choices) {
        int sel = choice->GetSelection();
        if (sel > 0) {  // 0 = Global
            plate->filament_preset_names.push_back(
                choice->GetString(sel).ToStdString()
            );
        } else {
            // Use global for this extruder
            plate->filament_preset_names.push_back(
                preset_bundle->filament_presets[filament_choices.size()]
            );
        }
    }
} else {
    plate->filament_preset_names.clear();
}
```

---

## Phase 3: Background Slicing Integration

### Step 3.1: Per-Plate Slicing

**File:** `src/slic3r/GUI/BackgroundSlicingProcess.cpp`

```cpp
void BackgroundSlicingProcess::process_multi_plate()
{
    // Get plate list
    const std::vector<PlateData*>& plates = get_plates();

    for (size_t plate_idx = 0; plate_idx < plates.size(); ++plate_idx) {
        PlateData* plate = plates[plate_idx];

        // Resolve config for this plate
        DynamicPrintConfig plate_config = m_print->resolve_config_for_plate(plate_idx);

        // Temporarily apply plate config
        DynamicPrintConfig saved_config = m_print->config();
        m_print->apply_config(plate_config);

        // Slice this plate
        slice_plate(plate_idx);

        // Restore global config
        m_print->apply_config(saved_config);
    }
}

void BackgroundSlicingProcess::slice_plate(int plate_idx)
{
    // Existing slicing logic, but for specific plate
    // ... (implementation depends on existing slice flow)
}
```

---

### Step 3.2: Invalidation Logic

**File:** `src/slic3r/GUI/Plater.cpp`

```cpp
void Plater::priv::on_plate_settings_changed(int plate_idx)
{
    // Invalidate only this plate's slicing
    invalidate_plate(plate_idx);

    // Schedule re-slice
    background_process.schedule_reslice_for_plate(plate_idx);
}

void Plater::priv::invalidate_plate(int plate_idx)
{
    PlateData* plate = partplate_list.get_plate(plate_idx);
    if (!plate)
        return;

    // Clear cached G-code
    plate->gcode_file.clear();
    plate->gcode_prediction.clear();

    // Mark plate as needs reslicing
    plate->needs_reslice = true;
}
```

---

## Validation & Error Handling

### Validation Checks

**File:** `src/slic3r/GUI/Plater.cpp`

```cpp
std::vector<std::string> Plater::priv::validate_plate_settings(int plate_idx)
{
    std::vector<std::string> warnings;
    PlateData* plate = partplate_list.get_plate(plate_idx);
    if (!plate)
        return warnings;

    // 1. Bed size check
    if (plate->has_custom_printer()) {
        const Preset* printer = preset_bundle->printers.find_preset(
            plate->printer_preset_name, false
        );
        if (printer) {
            BoundingBoxf plate_bb = get_plate_bounding_box(plate_idx);
            Vec2d bed_size = get_bed_size_from_preset(*printer);

            if (plate_bb.max.x() > bed_size.x() || plate_bb.max.y() > bed_size.y()) {
                warnings.push_back("Objects exceed printer bed size");
            }
        }
    }

    // 2. Filament count check
    if (plate->has_custom_printer() || plate->has_custom_filaments()) {
        int expected_extruders = get_extruder_count_for_plate(plate_idx);
        int actual_filaments = plate->has_custom_filaments() ?
            plate->filament_preset_names.size() :
            preset_bundle->filament_presets.size();

        if (expected_extruders != actual_filaments) {
            warnings.push_back(wxString::Format(
                "Filament count mismatch: printer has %d extruders, %d filaments specified",
                expected_extruders, actual_filaments
            ));
        }
    }

    // 3. Nozzle size compatibility
    if (plate->has_custom_printer()) {
        // Check if line widths are compatible with nozzle size
        // ... (implementation)
    }

    // 4. Printer capability check
    // Check if printer supports required features (multi-material, etc.)

    return warnings;
}
```

---

## Testing Strategy

### Unit Tests

```cpp
TEST_CASE("PlateData custom printer", "[plate]") {
    PlateData plate;
    REQUIRE(!plate.has_custom_printer());

    plate.printer_preset_name = "Printer A";
    REQUIRE(plate.has_custom_printer());

    std::string effective = plate.get_effective_printer_preset("Global");
    REQUIRE(effective == "Printer A");

    plate.printer_preset_name.clear();
    effective = plate.get_effective_printer_preset("Global");
    REQUIRE(effective == "Global");
}

TEST_CASE("Config resolution", "[print]") {
    Print print;
    // Setup: Create plate with custom printer
    // ... (implementation)

    DynamicPrintConfig resolved = print.resolve_config_for_plate(0);
    // Verify printer settings from custom preset
    // ...
}
```

---

### Integration Tests

1. **Simple Per-Plate Printer:**
   - [ ] Create 2-plate project
   - [ ] Plate 1: use global printer
   - [ ] Plate 2: set custom printer "Printer B"
   - [ ] Slice both plates
   - [ ] Verify: Each plate uses correct printer config
   - [ ] Save/reload project
   - [ ] Verify: Plate settings preserved

2. **Per-Plate Filaments:**
   - [ ] Create 3-plate project
   - [ ] Plate 1: Global filaments (PLA)
   - [ ] Plate 2: Custom filaments (PETG)
   - [ ] Plate 3: Mixed (PLA + TPU)
   - [ ] Slice all plates
   - [ ] Verify: G-code uses correct filament temps/speeds

3. **Validation:**
   - [ ] Create plate with objects wider than custom printer bed
   - [ ] Try to save with validation error
   - [ ] Verify: Warning shown, but save allowed
   - [ ] Verify: Visual indicator on plate

---

### Manual Test Cases

**Test 1: Basic Per-Plate Printer**
1. Create new project
2. Add object to Plate 1
3. Add object to Plate 2
4. Right-click Plate 2 → "Plate settings..."
5. Check "Use custom printer"
6. Select different printer from dropdown
7. Click OK
8. Verify: Plate 2 shows settings badge
9. Slice both plates
10. Compare G-code: verify different printer settings

**Test 2: Per-Plate Filaments**
1. Create 2-plate multi-material project
2. Plate 1: use global filaments (PLA + PLA)
3. Plate 2: custom filaments (PETG + TPU)
4. Open Plate 2 settings
5. Check "Use custom filaments"
6. Select PETG for Filament 1, TPU for Filament 2
7. Click OK
8. Slice both plates
9. Check G-code: verify different temperatures

**Test 3: Save/Load**
1. Create project with per-plate settings
2. Save as 3MF
3. Close project
4. Reload 3MF
5. Verify: All plate settings preserved
6. Verify: Visual indicators correct
7. Slice plates
8. Verify: Correct configs used

---

## Known Limitations & Future Work

### Current Limitations

1. **Single Printer Model Only (Phase 1):**
   - All plates must use printers of same model family
   - Different configurations (nozzle sizes, etc.) allowed
   - Different printer models (e.g., P1P + X1C) NOT supported initially

2. **Manual Workflow:**
   - User must manually send each plate's G-code to correct printer
   - No automatic job distribution

3. **No Live Preview Switching:**
   - Preview shows config for current plate only
   - Switching plates doesn't auto-update preview config display

4. **Validation at Save Time:**
   - Bed size validation happens at save/slice, not real-time
   - User could drag objects out of bounds for custom printer

### Future Enhancements

**Priority 1: Multi-Printer Send**
```cpp
void Plater::send_all_plates_to_printers()
{
    for (int i = 0; i < plate_count(); ++i) {
        PlateData* plate = get_plate(i);
        std::string printer_ip = get_printer_ip_for_plate(plate);

        if (!printer_ip.empty()) {
            send_gcode_to_printer(plate->gcode_file, printer_ip);
        }
    }
}
```

**Priority 2: Real-Time Validation**
- Check bed bounds as objects are dragged
- Show red outline if object out of bounds for plate's printer

**Priority 3: Printer Assignment Matrix**
- GUI showing all plates × all printers
- Assign plates to physical printers
- Auto-distribute based on availability

**Priority 4: Profile Inheritance**
- "Inherit from Plate X" option
- Reduce duplication when multiple plates use similar settings

---

## Files to Create/Modify

| File | Action | Lines Est. |
|------|--------|------------|
| `PartPlate.hpp` | Extend PlateData | +30 |
| `Print.hpp` | Add resolve_config_for_plate | +10 |
| `Print.cpp` | Implement config resolution | +150 |
| `bbs_3mf.cpp` | Serialize per-plate presets | +50 |
| `Plater.hpp` | Add plate settings dialog | +20 |
| `Plater.cpp` | Implement plate settings UI | +300 |
| `PartPlateList.cpp` | Visual indicators | +50 |
| `BackgroundSlicingProcess.cpp` | Per-plate slicing | +100 |
| **Total** | **~710 lines** | |

---

## Time Breakdown

**Phase 1: Per-Plate Printer**
1. PlateData extension: **30 min**
2. Config resolution: **1 hour**
3. 3MF serialization: **1 hour**
4. GUI dialog: **2 hours**
5. Visual indicators: **30 min**
6. Validation: **1 hour**

**Subtotal: ~6 hours**

**Phase 2: Per-Plate Filaments**
1. PlateData extension: **30 min**
2. Config resolution (filaments): **1.5 hours**
3. 3MF serialization: **30 min**
4. GUI filament selection: **1.5 hours**

**Subtotal: ~4 hours**

**Phase 3: Background Slicing**
1. Per-plate slicing logic: **2 hours**
2. Invalidation handling: **1 hour**

**Subtotal: ~3 hours**

**Testing & Debugging:** 2-3 hours

**Total: ~15-16 hours** (split across 3 phases)

---

## Success Criteria

✅ **Phase 1 Complete When:**
- [ ] Plates can have custom printer assigned
- [ ] Plate settings dialog works
- [ ] Visual indicator shows on plates with custom settings
- [ ] Config resolution uses plate printer correctly
- [ ] Slicing uses correct printer config per plate
- [ ] Settings serialize/deserialize to 3MF correctly
- [ ] Validation warnings work

✅ **Phase 2 Complete When:**
- [ ] Plates can have custom filaments assigned
- [ ] Filament selection UI works (one per extruder)
- [ ] Config resolution uses plate filaments correctly
- [ ] G-code uses correct filament settings per plate
- [ ] Filament count validation works

✅ **Phase 3 Complete When:**
- [ ] Background slicing handles per-plate configs
- [ ] Invalidation only affects changed plates
- [ ] Performance acceptable for multi-plate projects

---

## Conclusion

Feature #2 is the most architecturally complex feature in this plan, requiring changes to core slicing logic, config resolution, serialization, and GUI.

**Recommendation:** Implement in 3 distinct phases as outlined:
1. **Phase 1 first** (per-plate printer) - proves concept, delivers value
2. **Phase 2 second** (per-plate filaments) - extends Phase 1 pattern
3. **Phase 3 last** (background slicing) - optimizes performance

Each phase can be tested independently before proceeding to the next.

**Alternative:** If time-constrained, implement only Phase 1 (per-plate printer), which provides 70% of the value with 40% of the effort.
