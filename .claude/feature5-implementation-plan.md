# Feature #5 Implementation Plan: Hierarchical Object Grouping

**Status:** 📋 Detailed Implementation Plan
**Estimated Time:** 4-5 hours
**Complexity:** Medium

---

## Overview

Add hierarchical grouping of ModelVolumes within a ModelObject, allowing users to organize multi-part assemblies with groups that maintain individual part colors but can be managed collectively.

**Key Benefits:**
- Organize complex assemblies (10+ parts)
- Group by function/subassembly
- Maintain individual part colors
- Collective operations (hide, transform, assign extruder)

---

## Architecture Design

### Data Model

```
ModelObject
├── volumes (vector<ModelVolume*>)  ← Existing
├── volume_groups (vector<unique_ptr<ModelVolumeGroup>>)  ← New
└── config

ModelVolumeGroup  ← New class
├── id (int, unique within object)
├── name (string)
├── volumes (vector<ModelVolume*>, non-owning pointers)
├── extruder_id (int, -1 = no override)
├── visible (bool)
└── serialize/deserialize methods

ModelVolume
├── ...existing members...
└── parent_group (ModelVolumeGroup*, nullable)  ← New
```

**Ownership:**
- `ModelObject` owns `ModelVolumeGroup` objects (unique_ptr)
- `ModelVolumeGroup` has non-owning pointers to `ModelVolume`
- `ModelVolume` has non-owning pointer back to parent group

---

## Step-by-Step Implementation

### Phase 1: Backend Data Model (Model.hpp/cpp)

#### Step 1.1: Define ModelVolumeGroup Class

**File:** `src/libslic3r/Model.hpp`
**Insert after ModelConfigObject (around line 100):**

```cpp
// Orca: Hierarchical volume grouping
class ModelVolumeGroup : public ObjectBase
{
public:
    std::string name;
    int id{-1};  // Unique within this ModelObject
    int extruder_id{-1};  // -1 = no override, use volume's extruder
    bool visible{true};

    std::vector<ModelVolume*> volumes;  // Non-owning pointers
    ModelObject* parent_object{nullptr};  // Back-reference

    ModelVolumeGroup() = default;
    explicit ModelVolumeGroup(const std::string& name, int id)
        : name(name), id(id) {}

    // Serialization
    template<class Archive> void serialize(Archive &ar) {
        ar(cereal::base_class<ObjectBase>(this),
           name, id, extruder_id, visible);
        // Note: volumes are serialized by reference (volume IDs)
    }

    // Check if volume is in this group
    bool contains_volume(const ModelVolume* vol) const {
        return std::find(volumes.begin(), volumes.end(), vol) != volumes.end();
    }

    // Add/remove volumes
    void add_volume(ModelVolume* vol);
    void remove_volume(ModelVolume* vol);
    void clear() { volumes.clear(); }

    size_t volume_count() const { return volumes.size(); }
    bool empty() const { return volumes.empty(); }
};

using ModelVolumeGroupPtr = std::unique_ptr<ModelVolumeGroup>;
using ModelVolumeGroupPtrs = std::vector<ModelVolumeGroupPtr>;
```

---

#### Step 1.2: Extend ModelVolume

**File:** `src/libslic3r/Model.hpp`
**In ModelVolume class (around line 150):**

Add member:
```cpp
// Orca: Parent group if this volume is grouped
ModelVolumeGroup* parent_group{nullptr};
```

Add methods:
```cpp
// Group membership
bool is_grouped() const { return parent_group != nullptr; }
ModelVolumeGroup* get_parent_group() { return parent_group; }
const ModelVolumeGroup* get_parent_group() const { return parent_group; }
void set_parent_group(ModelVolumeGroup* group) { parent_group = group; }
```

Update serialize method:
```cpp
template<class Archive> void serialize(Archive &ar) {
    // ...existing serialization...
    // Note: parent_group serialized via ModelObject's group list
}
```

---

#### Step 1.3: Extend ModelObject

**File:** `src/libslic3r/Model.hpp`
**In ModelObject class (around line 366):**

Add member:
```cpp
// Orca: Volume groups for hierarchical organization
ModelVolumeGroupPtrs volume_groups;
```

Add methods:
```cpp
// Group management
ModelVolumeGroup* add_volume_group(const std::string& name = "Group");
void delete_volume_group(size_t idx);
void delete_volume_group(ModelVolumeGroup* group);
ModelVolumeGroup* get_volume_group_by_id(int id);
const ModelVolumeGroup* get_volume_group_by_id(int id) const;

// Volume-group operations
void move_volume_to_group(ModelVolume* vol, ModelVolumeGroup* group);
void move_volume_out_of_group(ModelVolume* vol);
ModelVolumeGroup* get_group_for_volume(const ModelVolume* vol);

// Get next available group ID
int get_next_group_id() const;

// Serialization helper
template<class Archive> void serialize_groups(Archive &ar);
```

**Implementation:** `src/libslic3r/Model.cpp`

```cpp
ModelVolumeGroup* ModelObject::add_volume_group(const std::string& name)
{
    int id = get_next_group_id();
    auto group = std::make_unique<ModelVolumeGroup>(
        name.empty() ? "Group " + std::to_string(id) : name,
        id
    );
    group->parent_object = this;

    ModelVolumeGroup* ptr = group.get();
    volume_groups.push_back(std::move(group));
    return ptr;
}

void ModelObject::delete_volume_group(size_t idx)
{
    if (idx >= volume_groups.size())
        return;

    // Remove group reference from all volumes
    for (ModelVolume* vol : volume_groups[idx]->volumes) {
        vol->parent_group = nullptr;
    }

    volume_groups.erase(volume_groups.begin() + idx);
}

void ModelObject::delete_volume_group(ModelVolumeGroup* group)
{
    auto it = std::find_if(volume_groups.begin(), volume_groups.end(),
        [group](const ModelVolumeGroupPtr& g) { return g.get() == group; });
    if (it != volume_groups.end()) {
        delete_volume_group(std::distance(volume_groups.begin(), it));
    }
}

void ModelObject::move_volume_to_group(ModelVolume* vol, ModelVolumeGroup* group)
{
    if (!vol || !group)
        return;

    // Remove from old group if any
    if (vol->parent_group) {
        vol->parent_group->remove_volume(vol);
    }

    // Add to new group
    group->add_volume(vol);
    vol->parent_group = group;
}

void ModelObject::move_volume_out_of_group(ModelVolume* vol)
{
    if (!vol || !vol->parent_group)
        return;

    vol->parent_group->remove_volume(vol);
    vol->parent_group = nullptr;
}

int ModelObject::get_next_group_id() const
{
    int max_id = 0;
    for (const auto& group : volume_groups) {
        max_id = std::max(max_id, group->id);
    }
    return max_id + 1;
}

// ModelVolumeGroup implementations
void ModelVolumeGroup::add_volume(ModelVolume* vol)
{
    if (!vol || contains_volume(vol))
        return;
    volumes.push_back(vol);
}

void ModelVolumeGroup::remove_volume(ModelVolume* vol)
{
    auto it = std::find(volumes.begin(), volumes.end(), vol);
    if (it != volumes.end()) {
        volumes.erase(it);
    }
}
```

---

### Phase 2: 3MF Serialization (bbs_3mf.cpp)

#### Step 2.1: Export Groups to 3MF

**File:** `src/libslic3r/Format/bbs_3mf.cpp`
**In `_add_model_config_file_to_archive()` function (around line 7542):**

Add after object metadata export:

```cpp
// Orca: Export volume groups
if (!obj->volume_groups.empty()) {
    stream << "  <volumegroups>\n";
    for (const auto& group : obj->volume_groups) {
        stream << "    <group id=\"" << group->id << "\" name=\""
               << xml_escape(group->name) << "\" ";
        if (group->extruder_id >= 0) {
            stream << "extruder=\"" << group->extruder_id << "\" ";
        }
        stream << "visible=\"" << (group->visible ? "1" : "0") << "\">\n";

        // Export volume references
        for (const ModelVolume* vol : group->volumes) {
            // Find volume index
            auto it = std::find(obj->volumes.begin(), obj->volumes.end(), vol);
            if (it != obj->volumes.end()) {
                int vol_idx = std::distance(obj->volumes.begin(), it);
                stream << "      <volume refid=\"" << vol_idx << "\"/>\n";
            }
        }

        stream << "    </group>\n";
    }
    stream << "  </volumegroups>\n";
}
```

---

#### Step 2.2: Import Groups from 3MF

**File:** `src/libslic3r/Format/bbs_3mf.cpp`
**Add parser state members (in `_BBS_3MF_Importer` class):**

```cpp
// Orca: Group parsing state
struct GroupParseState {
    int id{-1};
    std::string name;
    int extruder_id{-1};
    bool visible{true};
    std::vector<int> volume_indices;
};
GroupParseState m_current_group;
std::vector<GroupParseState> m_parsed_groups;
ModelObject* m_current_parse_object{nullptr};
```

**Add XML handlers:**

```cpp
bool _handle_start_volumegroups(const char** attributes, unsigned int num_attributes)
{
    // Start of volumegroups section
    m_parsed_groups.clear();
    return true;
}

bool _handle_end_volumegroups()
{
    // Apply parsed groups to current object
    if (m_current_parse_object) {
        for (const auto& group_data : m_parsed_groups) {
            auto* group = m_current_parse_object->add_volume_group(group_data.name);
            group->id = group_data.id;
            group->extruder_id = group_data.extruder_id;
            group->visible = group_data.visible;

            // Add volumes to group
            for (int vol_idx : group_data.volume_indices) {
                if (vol_idx >= 0 && vol_idx < m_current_parse_object->volumes.size()) {
                    ModelVolume* vol = m_current_parse_object->volumes[vol_idx];
                    group->add_volume(vol);
                    vol->parent_group = group;
                }
            }
        }
    }
    m_parsed_groups.clear();
    return true;
}

bool _handle_start_group(const char** attributes, unsigned int num_attributes)
{
    m_current_group = GroupParseState();
    m_current_group.id = bbs_get_attribute_value_int(attributes, num_attributes, "id");
    m_current_group.name = bbs_get_attribute_value_string(attributes, num_attributes, "name");

    std::string extruder_str = bbs_get_attribute_value_string(attributes, num_attributes, "extruder");
    if (!extruder_str.empty()) {
        m_current_group.extruder_id = std::stoi(extruder_str);
    }

    std::string visible_str = bbs_get_attribute_value_string(attributes, num_attributes, "visible");
    m_current_group.visible = (visible_str != "0");

    return true;
}

bool _handle_end_group()
{
    m_parsed_groups.push_back(m_current_group);
    m_current_group = GroupParseState();
    return true;
}

bool _handle_group_volume(const char** attributes, unsigned int num_attributes)
{
    int refid = bbs_get_attribute_value_int(attributes, num_attributes, "refid");
    m_current_group.volume_indices.push_back(refid);
    return true;
}
```

**Register handlers in XML parser init:**

```cpp
// In parser setup
register_start_element_handler("volumegroups", [this](const char** attrs, unsigned int num) {
    return _handle_start_volumegroups(attrs, num);
});
register_end_element_handler("volumegroups", [this]() {
    return _handle_end_volumegroups();
});
register_start_element_handler("group", [this](const char** attrs, unsigned int num) {
    return _handle_start_group(attrs, num);
});
register_end_element_handler("group", [this]() {
    return _handle_end_group();
});
register_start_element_handler("volume", [this](const char** attrs, unsigned int num) {
    // Check if we're inside a group
    if (m_in_group_context) {
        return _handle_group_volume(attrs, num);
    }
    // ... existing volume handler
});
```

---

### Phase 3: GUI ObjectList Tree View

#### Step 3.1: Add Group Item Type

**File:** `src/slic3r/GUI/GUI_ObjectList.hpp`
**In `ItemType` enum:**

```cpp
enum class ItemType : int {
    itUndef         = 0,
    itObject        = 1,
    itVolume        = 2,
    itInstance      = 4,
    itSettings      = 8,
    itLayerRoot     = 16,
    itLayer         = 32,
    itInfo          = 64,
    itPlate         = 128,
    itVolumeGroup   = 256,  // Orca: Volume group
};
```

---

#### Step 3.2: Extend Tree Model

**File:** `src/slic3r/GUI/GUI_ObjectList.cpp`
**In `ObjectDataViewModel` class:**

```cpp
void ObjectDataViewModel::UpdateObjectsInList(size_t obj_idx, const ModelObject* object)
{
    // ... existing code ...

    // Orca: Add volume groups
    for (const auto& group : object->volume_groups) {
        wxDataViewItem group_item = wxDataViewItem((void*)group.get());
        AddGroupItemToObjectTree(group_item, obj_idx, group.get());

        // Add volumes under this group
        for (const ModelVolume* vol : group->volumes) {
            wxDataViewItem vol_item = wxDataViewItem((void*)vol);
            AddVolumeChild(group_item, vol_item);
            ItemAdded(group_item, vol_item);
        }
    }

    // Add ungrouped volumes at root level
    for (ModelVolume* vol : object->volumes) {
        if (!vol->parent_group) {
            wxDataViewItem vol_item = wxDataViewItem((void*)vol);
            AddVolumeChild(obj_item, vol_item);
            ItemAdded(obj_item, vol_item);
        }
    }
}
```

---

#### Step 3.3: Group Context Menu Operations

**File:** `src/slic3r/GUI/GUI_ObjectList.cpp`
**Add menu items:**

```cpp
void ObjectList::append_menu_items_group(wxMenu* menu)
{
    append_menu_item(menu, wxID_ANY, _L("Rename group"), "",
        [this](wxCommandEvent&) { rename_item(); }, "rename", menu);

    append_menu_item(menu, wxID_ANY, _L("Set extruder"), "",
        [this](wxCommandEvent&) { set_group_extruder(); }, "extruder", menu);

    menu->AppendSeparator();

    append_menu_item(menu, wxID_ANY, _L("Ungroup"), "",
        [this](wxCommandEvent&) { ungroup_volumes(); }, "ungroup", menu);

    append_menu_item(menu, wxID_ANY, _L("Delete group"), "",
        [this](wxCommandEvent&) { delete_group(); }, "delete", menu);
}

void ObjectList::append_menu_items_add_volumes(wxMenu* menu)
{
    // ... existing items ...

    menu->AppendSeparator();

    wxMenu* group_menu = new wxMenu();
    append_menu_item(group_menu, wxID_ANY, _L("Create group from selection"), "",
        [this](wxCommandEvent&) { create_group_from_selection(); }, "group", menu);

    // Add submenu for existing groups
    wxDataViewItemArray sels;
    GetSelections(sels);
    if (!sels.IsEmpty()) {
        auto obj = object(m_objects_model->GetObjectIdByItem(sels[0]));
        if (obj && !obj->volume_groups.empty()) {
            group_menu->AppendSeparator();
            for (const auto& group : obj->volume_groups) {
                append_menu_item(group_menu, wxID_ANY,
                    wxString::Format(_L("Add to '%s'"), group->name), "",
                    [this, group = group.get()](wxCommandEvent&) {
                        add_selection_to_group(group);
                    }, "", menu);
            }
        }
    }

    menu->AppendSubMenu(group_menu, _L("Groups"));
}
```

---

#### Step 3.4: Group Operations Implementation

```cpp
void ObjectList::create_group_from_selection()
{
    wxDataViewItemArray sels;
    GetSelections(sels);
    if (sels.IsEmpty())
        return;

    // Get selected volumes
    std::vector<ModelVolume*> volumes;
    int obj_idx = -1;
    for (auto item : sels) {
        ItemType type = m_objects_model->GetItemType(item);
        if (type == itVolume) {
            if (obj_idx < 0)
                obj_idx = m_objects_model->GetObjectIdByItem(item);
            auto vol = m_objects_model->GetModelVolume(item);
            if (vol)
                volumes.push_back(vol);
        }
    }

    if (volumes.empty() || obj_idx < 0)
        return;

    auto obj = (*m_objects)[obj_idx];

    // Create group
    auto group = obj->add_volume_group("Group");

    // Move volumes to group
    for (auto vol : volumes) {
        obj->move_volume_to_group(vol, group);
    }

    // Update UI
    update_object(obj_idx);
    select_item([group]() { return wxDataViewItem((void*)group); });
}

void ObjectList::ungroup_volumes()
{
    auto item = GetSelection();
    if (!item.IsOk())
        return;

    if (m_objects_model->GetItemType(item) != itVolumeGroup)
        return;

    auto group = (ModelVolumeGroup*)item.GetID();
    if (!group)
        return;

    int obj_idx = m_objects_model->GetObjectIdByItem(item);
    auto obj = (*m_objects)[obj_idx];

    // Move volumes out of group
    std::vector<ModelVolume*> vols_copy = group->volumes;  // Copy because we're modifying
    for (auto vol : vols_copy) {
        obj->move_volume_out_of_group(vol);
    }

    // Delete group
    obj->delete_volume_group(group);

    // Update UI
    update_object(obj_idx);
}

void ObjectList::add_selection_to_group(ModelVolumeGroup* group)
{
    wxDataViewItemArray sels;
    GetSelections(sels);

    int obj_idx = m_objects_model->GetObjectIdByItem(sels[0]);
    auto obj = (*m_objects)[obj_idx];

    for (auto item : sels) {
        if (m_objects_model->GetItemType(item) == itVolume) {
            auto vol = m_objects_model->GetModelVolume(item);
            if (vol) {
                obj->move_volume_to_group(vol, group);
            }
        }
    }

    update_object(obj_idx);
}

void ObjectList::set_group_extruder()
{
    auto item = GetSelection();
    if (!item.IsOk())
        return;

    auto group = (ModelVolumeGroup*)item.GetID();
    if (!group)
        return;

    // Show extruder selection dialog
    wxArrayString choices;
    choices.Add(_L("No override"));
    for (int i = 1; i <= extruders_count(); ++i) {
        choices.Add(wxString::Format("Extruder %d", i));
    }

    int current = group->extruder_id + 1;  // +1 because -1 = "No override"
    int selection = wxGetSingleChoiceIndex(_L("Select extruder for group:"),
                                          _L("Group Extruder"),
                                          choices,
                                          current);
    if (selection >= 0) {
        group->extruder_id = selection - 1;  // -1 to convert back
        update_in_scene();
    }
}
```

---

### Phase 4: Selection Handling

#### Step 4.1: Group Selection in GLCanvas

**File:** `src/slic3r/GUI/Selection.cpp`

```cpp
void Selection::add_volume_group(const ModelVolumeGroup* group)
{
    if (!group)
        return;

    // Select all volumes in the group
    for (const ModelVolume* vol : group->volumes) {
        // Find volume in scene
        for (unsigned int vol_idx = 0; vol_idx < m_volumes->size(); ++vol_idx) {
            if ((*m_volumes)[vol_idx]->volume == vol) {
                add_volume(vol_idx, false);  // false = don't update
            }
        }
    }

    update_type();  // Update selection type
    m_selected_group = group;  // Track group selection
}

void Selection::remove_volume_group(const ModelVolumeGroup* group)
{
    if (!group)
        return;

    for (const ModelVolume* vol : group->volumes) {
        for (unsigned int vol_idx = 0; vol_idx < m_volumes->size(); ++vol_idx) {
            if ((*m_volumes)[vol_idx]->volume == vol) {
                remove_volume(vol_idx);
            }
        }
    }

    if (m_selected_group == group)
        m_selected_group = nullptr;
}

BoundingBoxf3 Selection::get_group_bounding_box(const ModelVolumeGroup* group) const
{
    BoundingBoxf3 bb;
    for (const ModelVolume* vol : group->volumes) {
        bb.merge(vol->get_convex_hull().bounding_box());
    }
    return bb;
}
```

---

#### Step 4.2: Group Bounding Box Rendering

**File:** `src/slic3r/GUI/GLCanvas3D.cpp`

```cpp
void GLCanvas3D::render_group_bounding_box()
{
    const Selection& selection = m_selection;
    if (!selection.has_selected_group())
        return;

    const ModelVolumeGroup* group = selection.get_selected_group();
    if (!group)
        return;

    BoundingBoxf3 box = selection.get_group_bounding_box(group);
    if (!box.defined)
        return;

    // Render dashed bounding box
    glEnable(GL_LINE_STIPPLE);
    glLineStipple(1, 0x0F0F);  // Dashed pattern
    glLineWidth(2.0f);

    GLShaderProgram* shader = wxGetApp().get_shader("flat");
    if (shader) {
        shader->start_using();
        shader->set_uniform("view_model_matrix", Transform3d::Identity());
        shader->set_uniform("projection_matrix", wxGetApp().plater()->get_camera().get_projection_matrix());

        // Render box edges
        render_bounding_box_edges(box, ColorRGBA(0.0f, 0.5f, 1.0f, 0.8f));  // Blue

        shader->stop_using();
    }

    glDisable(GL_LINE_STIPPLE);
}

// Call from main render loop
void GLCanvas3D::render()
{
    // ... existing render code ...

    // Orca: Render group bounding box if group selected
    render_group_bounding_box();
}
```

---

### Phase 5: Group Properties Panel

**File:** `src/slic3r/GUI/GUI_ObjectSettings.cpp`

```cpp
bool ObjectSettings::update_settings_list()
{
    // ... existing code ...

    // Check if group is selected
    if (m_objects_model->GetItemType(item) == itVolumeGroup) {
        auto group = (ModelVolumeGroup*)item.GetID();
        if (group) {
            show_group_settings(group);
            return true;
        }
    }

    // ... rest of existing code ...
}

void ObjectSettings::show_group_settings(ModelVolumeGroup* group)
{
    clear_settings();

    // Group name
    wxBoxSizer* name_sizer = new wxBoxSizer(wxHORIZONTAL);
    name_sizer->Add(new wxStaticText(this, wxID_ANY, _L("Group name:")), 0, wxALIGN_CENTER_VERTICAL);
    wxTextCtrl* name_ctrl = new wxTextCtrl(this, wxID_ANY, group->name);
    name_ctrl->Bind(wxEVT_TEXT, [this, group](wxCommandEvent& e) {
        group->name = e.GetString().ToStdString();
        wxGetApp().obj_list()->update_name_in_list(group);
    });
    name_sizer->Add(name_ctrl, 1, wxEXPAND | wxLEFT, 5);
    m_settings_list_sizer->Add(name_sizer, 0, wxEXPAND | wxALL, 5);

    // Extruder override
    wxBoxSizer* extruder_sizer = new wxBoxSizer(wxHORIZONTAL);
    extruder_sizer->Add(new wxStaticText(this, wxID_ANY, _L("Extruder:")), 0, wxALIGN_CENTER_VERTICAL);

    wxArrayString choices;
    choices.Add(_L("Use volume extruder"));
    for (int i = 1; i <= extruders_count(); ++i) {
        choices.Add(wxString::Format("Extruder %d", i));
    }

    wxChoice* extruder_choice = new wxChoice(this, wxID_ANY, wxDefaultPosition, wxDefaultSize, choices);
    extruder_choice->SetSelection(group->extruder_id + 1);
    extruder_choice->Bind(wxEVT_CHOICE, [this, group](wxCommandEvent& e) {
        group->extruder_id = e.GetSelection() - 1;
        wxGetApp().plater()->update();
    });
    extruder_sizer->Add(extruder_choice, 1, wxEXPAND | wxLEFT, 5);
    m_settings_list_sizer->Add(extruder_sizer, 0, wxEXPAND | wxALL, 5);

    // Visible checkbox
    wxCheckBox* visible_check = new wxCheckBox(this, wxID_ANY, _L("Visible"));
    visible_check->SetValue(group->visible);
    visible_check->Bind(wxEVT_CHECKBOX, [this, group](wxCommandEvent& e) {
        group->visible = e.IsChecked();
        wxGetApp().plater()->update();
    });
    m_settings_list_sizer->Add(visible_check, 0, wxALL, 5);

    // Volume count info
    wxString info = wxString::Format(_L("Contains %d volumes"), group->volume_count());
    m_settings_list_sizer->Add(new wxStaticText(this, wxID_ANY, info), 0, wxALL, 5);

    Layout();
}
```

---

## Testing Checklist

### Unit Tests
- [ ] Create group → verify ID assigned correctly
- [ ] Add volumes to group → verify parent_group set
- [ ] Remove volume from group → verify parent_group cleared
- [ ] Delete group → verify volumes unlinked
- [ ] Serialize/deserialize → verify groups preserved

### Integration Tests
- [ ] Create group with 3 volumes
- [ ] Save project as 3MF
- [ ] Reload project
- [ ] Verify: group structure maintained, volumes in correct group

### Manual Tests
1. **Create Group:**
   - [ ] Load object with 5 volumes
   - [ ] Select volumes 1,2,3
   - [ ] Right-click → "Create group from selection"
   - [ ] Verify: group appears in tree, volumes nested under it

2. **Rename Group:**
   - [ ] Select group
   - [ ] Right-click → "Rename"
   - [ ] Enter new name
   - [ ] Verify: name updates in tree

3. **Set Group Extruder:**
   - [ ] Select group
   - [ ] Right-click → "Set extruder" → "Extruder 2"
   - [ ] Verify: all volumes in group use extruder 2

4. **Ungroup:**
   - [ ] Select group
   - [ ] Right-click → "Ungroup"
   - [ ] Verify: volumes move to root, group deleted

5. **Group Selection:**
   - [ ] Click group in tree
   - [ ] Verify: all volumes highlighted in 3D view
   - [ ] Verify: blue dashed bounding box around group

6. **Serialization:**
   - [ ] Create complex hierarchy (2 groups, mixed volumes)
   - [ ] Save → reload
   - [ ] Verify: structure identical

---

## Files to Create/Modify

| File | Action | Lines Est. |
|------|--------|------------|
| `Model.hpp` | Add ModelVolumeGroup class | +80 |
| `Model.cpp` | Implement group methods | +150 |
| `bbs_3mf.cpp` | Export/import groups | +100 |
| `GUI_ObjectList.hpp` | Add itVolumeGroup enum | +1 |
| `GUI_ObjectList.cpp` | Tree view + operations | +300 |
| `Selection.hpp` | Add group selection | +20 |
| `Selection.cpp` | Implement group selection | +80 |
| `GLCanvas3D.cpp` | Render group bbox | +50 |
| `GUI_ObjectSettings.cpp` | Group properties panel | +80 |
| **Total** | **~860 lines** | |

---

## Estimated Time Breakdown

1. Backend data model (Model.hpp/cpp): **1.5 hours**
2. 3MF serialization (bbs_3mf.cpp): **1 hour**
3. GUI tree view (GUI_ObjectList): **1.5 hours**
4. Selection handling (Selection.cpp): **0.5 hours**
5. Properties panel (GUI_ObjectSettings.cpp): **0.5 hours**
6. Testing and debugging: **1 hour**

**Total: ~5-6 hours**

---

## Success Criteria

✅ **Complete when:**
- [ ] Groups can be created from selection
- [ ] Groups appear in object tree with volumes nested
- [ ] Groups can be renamed
- [ ] Group extruder override works
- [ ] Ungroup operation works
- [ ] Groups serialize/deserialize to 3MF correctly
- [ ] Clicking group selects all volumes
- [ ] Group bounding box renders in 3D view
- [ ] No crashes or memory leaks

---

## Future Enhancements

**Priority 1: Drag-and-Drop**
- Drag volumes into/out of groups in tree view

**Priority 2: Group Templates**
- Save/load group configurations
- Apply to similar assemblies

**Priority 3: Group Transform**
- Transform entire group collectively
- Maintain relative positions

**Priority 4: Nested Groups**
- Groups within groups (subassemblies within assemblies)
- More complex but powerful organization

---

## Conclusion

Feature #5 provides a well-scoped enhancement for organizing complex multi-part assemblies. The implementation follows OrcaSlicer's existing patterns for data model, serialization, and GUI integration.

**Key Design Decisions:**
1. **Non-owning pointers:** Groups don't own volumes, simplifies memory management
2. **Optional XML section:** 3MF backward compatible, older versions ignore groups
3. **Tree-based UI:** Familiar pattern from CAD software, intuitive for users
4. **Per-group extruder:** Override applies to all volumes, simplifies multi-material setup

**Next:** Proceed to Feature #2 (Per-Plate Settings) after implementing this feature.
