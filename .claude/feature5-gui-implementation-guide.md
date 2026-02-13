# Feature #5 GUI Implementation Guide: Phases 3-5

**Date:** 2026-02-13
**Status:** Backend Complete (Phases 1-2 ✅), GUI Implementation Guide (Phases 3-5)

---

## Prerequisites (Already Complete ✅)

1. **Backend Data Model** - Model.hpp/cpp with ModelVolumeGroup class
2. **3MF Serialization** - bbs_3mf.cpp with group import/export
3. **ItemType Enum** - ObjectDataViewModel.hpp with itVolumeGroup = 512

---

## Phase 3: GUI ObjectList Tree View

### Goal
Display groups in the object tree with volumes nested underneath, and provide context menu operations for group management.

### Step 3.1: Extend ObjectDataViewModel

**File:** `src/slic3r/GUI/ObjectDataViewModel.cpp`

**Find:** The section where volume nodes are added to the tree (search for "itVolume" node creation)

**Add:** Group node creation logic

```cpp
// Orca: Add group nodes to object tree
void ObjectDataViewModel::AddGroupToObject(const wxDataViewItem& parent_item,
                                           const ModelVolumeGroup* group,
                                           int obj_idx)
{
    const wxString group_name = from_u8(group->name);
    const auto node = new ObjectDataViewModelNode(parent_item, group_name);
    node->set_type(itVolumeGroup);
    node->set_idx(group->id);

    // Set group icon (use folder icon or custom group icon)
    node->set_bitmap(*m_volume_bmps[0]);  // Or create custom group bitmap

    // Add extruder info if group has override
    if (group->extruder_id >= 0) {
        node->set_extruder(wxString::Format("%d", group->extruder_id + 1));
    }

    // Insert group node
    InsertChild(parent_item, node);
}
```

**Add:** Method to rebuild object tree with groups

```cpp
void ObjectDataViewModel::UpdateObjectWithGroups(size_t obj_idx, ModelObject* object)
{
    if (!object || obj_idx >= m_objects.size())
        return;

    const wxDataViewItem obj_item = m_objects[obj_idx];

    // First, add all groups
    for (const auto& group : object->volume_groups) {
        AddGroupToObject(obj_item, group.get(), obj_idx);

        const wxDataViewItem group_item = GetGroupItem(obj_idx, group->id);

        // Add volumes that belong to this group
        for (ModelVolume* vol : group->volumes) {
            AddVolumeToGroup(group_item, vol, obj_idx);
        }
    }

    // Then add ungrouped volumes directly to object
    for (ModelVolume* vol : object->volumes) {
        if (!vol->is_grouped()) {
            AddVolumeChild(obj_item, vol, obj_idx);
        }
    }
}
```

**Add:** Helper method to find group item

```cpp
wxDataViewItem ObjectDataViewModel::GetGroupItem(int obj_idx, int group_id) const
{
    if (obj_idx < 0 || obj_idx >= m_objects.size())
        return wxDataViewItem(nullptr);

    const wxDataViewItem obj_item = m_objects[obj_idx];
    ObjectDataViewModelNode* obj_node = static_cast<ObjectDataViewModelNode*>(obj_item.GetID());

    for (size_t i = 0; i < obj_node->GetChildCount(); ++i) {
        ObjectDataViewModelNode* child = obj_node->GetNthChild(i);
        if (child->GetType() == itVolumeGroup && child->GetIdx() == group_id) {
            return wxDataViewItem(child);
        }
    }

    return wxDataViewItem(nullptr);
}
```

---

### Step 3.2: Context Menu for Groups

**File:** `src/slic3r/GUI/GUI_ObjectList.cpp`

**Find:** The method that creates context menus (search for "append_menu_item" or "OnContextMenu")

**Add:** Group-specific menu items

```cpp
void ObjectList::create_group_context_menu(wxMenu* menu)
{
    // Rename group
    append_menu_item(menu, wxID_ANY, _L("Rename"), "",
        [this](wxCommandEvent&) { rename_item(); }, "rename");

    menu->AppendSeparator();

    // Set extruder for group
    wxMenu* extruder_menu = new wxMenu();
    extruder_menu->Append(wxID_ANY, _L("Default"));
    for (int i = 0; i < extruders_count(); ++i) {
        extruder_menu->Append(wxID_ANY, wxString::Format("Extruder %d", i + 1));
    }
    extruder_menu->Bind(wxEVT_MENU, [this](wxCommandEvent& e) {
        set_group_extruder(e.GetId());
    });
    menu->AppendSubMenu(extruder_menu, _L("Set extruder"));

    menu->AppendSeparator();

    // Ungroup
    append_menu_item(menu, wxID_ANY, _L("Ungroup"), "",
        [this](wxCommandEvent&) { ungroup_volumes(); }, "ungroup");

    // Delete group
    append_menu_item(menu, wxID_ANY, _L("Delete group"), "",
        [this](wxCommandEvent&) { delete_group(); }, "delete");
}
```

**Add:** "Create group" to volume context menu

```cpp
void ObjectList::append_group_menu_items(wxMenu* menu)
{
    // Only show if multiple volumes selected
    wxDataViewItemArray sels;
    GetSelections(sels);

    int volume_count = 0;
    for (const auto& item : sels) {
        if (m_objects_model->GetItemType(item) == itVolume)
            volume_count++;
    }

    if (volume_count < 2)
        return;  // Need at least 2 volumes to create group

    menu->AppendSeparator();

    // Create group from selection
    append_menu_item(menu, wxID_ANY, _L("Create group from selection"), "",
        [this](wxCommandEvent&) { create_group_from_selection(); }, "group");

    // Add to existing group submenu
    auto obj = object(get_selected_obj_idx());
    if (obj && !obj->volume_groups.empty()) {
        wxMenu* add_to_group_menu = new wxMenu();

        for (const auto& group : obj->volume_groups) {
            add_to_group_menu->Append(wxID_ANY, from_u8(group->name));
        }

        add_to_group_menu->Bind(wxEVT_MENU, [this](wxCommandEvent& e) {
            add_selection_to_group(e.GetId());
        });

        menu->AppendSubMenu(add_to_group_menu, _L("Add to group"));
    }
}
```

---

### Step 3.3: Group Operations Implementation

**File:** `src/slic3r/GUI/GUI_ObjectList.cpp`

**Add:** Create group from selection

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

    for (const auto& item : sels) {
        if (m_objects_model->GetItemType(item) != itVolume)
            continue;

        if (obj_idx < 0)
            obj_idx = m_objects_model->GetObjectIdByItem(item);

        ModelVolume* vol = get_model_volume(item, obj_idx);
        if (vol)
            volumes.push_back(vol);
    }

    if (volumes.empty() || obj_idx < 0)
        return;

    auto obj = (*m_objects)[obj_idx];

    // Prompt for group name
    wxTextEntryDialog dialog(this, _L("Enter group name:"), _L("Create Group"), "Group");
    if (dialog.ShowModal() != wxID_OK)
        return;

    wxString group_name = dialog.GetValue();
    if (group_name.IsEmpty())
        group_name = "Group";

    // Create group
    ModelVolumeGroup* group = obj->add_volume_group(group_name.ToStdString());

    // Move volumes to group
    for (auto vol : volumes) {
        obj->move_volume_to_group(vol, group);
    }

    // Update tree
    update_object(obj_idx);

    // Select the new group
    select_item([this, obj_idx, group]() {
        return m_objects_model->GetGroupItem(obj_idx, group->id);
    });

    // Mark as modified
    part_selection_changed();
}
```

**Add:** Ungroup operation

```cpp
void ObjectList::ungroup_volumes()
{
    const auto item = GetSelection();
    if (!item.IsOk())
        return;

    if (m_objects_model->GetItemType(item) != itVolumeGroup)
        return;

    int obj_idx = m_objects_model->GetObjectIdByItem(item);
    int group_id = m_objects_model->GetVolumeIdByItem(item);

    auto obj = (*m_objects)[obj_idx];
    ModelVolumeGroup* group = obj->get_volume_group_by_id(group_id);

    if (!group)
        return;

    // Ask for confirmation
    wxString msg = wxString::Format(_L("Ungroup '%s'?\nVolumes will remain but group will be deleted."),
                                    from_u8(group->name));
    wxMessageDialog confirm(this, msg, _L("Confirm Ungroup"), wxYES_NO | wxICON_QUESTION);
    if (confirm.ShowModal() != wxID_YES)
        return;

    // Copy volume list (will be modified during iteration)
    std::vector<ModelVolume*> vols_copy = group->volumes;

    // Move all volumes out of group
    for (auto vol : vols_copy) {
        obj->move_volume_out_of_group(vol);
    }

    // Delete the group
    obj->delete_volume_group(group);

    // Update tree
    update_object(obj_idx);

    // Mark as modified
    part_selection_changed();
}
```

**Add:** Set group extruder

```cpp
void ObjectList::set_group_extruder(int menu_id)
{
    const auto item = GetSelection();
    if (!item.IsOk())
        return;

    if (m_objects_model->GetItemType(item) != itVolumeGroup)
        return;

    int obj_idx = m_objects_model->GetObjectIdByItem(item);
    int group_id = m_objects_model->GetVolumeIdByItem(item);

    auto obj = (*m_objects)[obj_idx];
    ModelVolumeGroup* group = obj->get_volume_group_by_id(group_id);

    if (!group)
        return;

    // Determine selected extruder (-1 for default, or 0-based extruder index)
    int extruder = menu_id - BASE_EXTRUDER_MENU_ID;  // Adjust based on menu ID scheme

    group->extruder_id = extruder;

    // Update tree display
    m_objects_model->UpdateGroupExtruder(obj_idx, group_id, extruder);

    // Mark as modified
    part_selection_changed();
}
```

**Add:** Delete group

```cpp
void ObjectList::delete_group()
{
    const auto item = GetSelection();
    if (!item.IsOk())
        return;

    if (m_objects_model->GetItemType(item) != itVolumeGroup)
        return;

    int obj_idx = m_objects_model->GetObjectIdByItem(item);
    int group_id = m_objects_model->GetVolumeIdByItem(item);

    auto obj = (*m_objects)[obj_idx];
    ModelVolumeGroup* group = obj->get_volume_group_by_id(group_id);

    if (!group)
        return;

    // Ask for confirmation
    wxString msg = wxString::Format(_L("Delete group '%s'?\nVolumes will remain ungrouped."),
                                    from_u8(group->name));
    wxMessageDialog confirm(this, msg, _L("Confirm Delete"), wxYES_NO | wxICON_QUESTION);
    if (confirm.ShowModal() != wxID_YES)
        return;

    // Delete group (volumes are automatically moved out)
    obj->delete_volume_group(group);

    // Update tree
    update_object(obj_idx);

    // Mark as modified
    part_selection_changed();
}
```

---

## Phase 4: Selection Handling

### Goal
Enable group selection in the 3D view, with all volumes highlighted when a group is clicked.

### Step 4.1: Extend Selection Class

**File:** `src/slic3r/GUI/Selection.hpp`

**Add:** Group selection members

```cpp
class Selection
{
private:
    const ModelVolumeGroup* m_selected_group{nullptr};

public:
    // Group selection
    bool has_selected_group() const { return m_selected_group != nullptr; }
    const ModelVolumeGroup* get_selected_group() const { return m_selected_group; }
    void add_volume_group(const ModelVolumeGroup* group);
    void remove_volume_group(const ModelVolumeGroup* group);
    void clear_group_selection() { m_selected_group = nullptr; }
    BoundingBoxf3 get_group_bounding_box(const ModelVolumeGroup* group) const;
};
```

**File:** `src/slic3r/GUI/Selection.cpp`

**Add:** Group selection implementation

```cpp
void Selection::add_volume_group(const ModelVolumeGroup* group)
{
    if (!group)
        return;

    clear();  // Clear existing selection

    // Select all volumes in the group
    for (const ModelVolume* vol : group->volumes) {
        // Find GLVolume indices for this ModelVolume
        for (unsigned int i = 0; i < m_volumes->size(); ++i) {
            const GLVolume* gl_vol = (*m_volumes)[i];
            if (gl_vol->object_idx() < 0 || gl_vol->volume_idx() < 0)
                continue;

            const ModelObject* obj = m_model->objects[gl_vol->object_idx()];
            if (gl_vol->volume_idx() < obj->volumes.size()) {
                const ModelVolume* mv = obj->volumes[gl_vol->volume_idx()];
                if (mv == vol) {
                    add_volume(i, false);  // Don't update yet
                }
            }
        }
    }

    m_selected_group = group;
    update_type();  // Update selection type
    wxGetApp().plater()->update();
}

void Selection::remove_volume_group(const ModelVolumeGroup* group)
{
    if (!group || m_selected_group != group)
        return;

    clear();
    m_selected_group = nullptr;
}

BoundingBoxf3 Selection::get_group_bounding_box(const ModelVolumeGroup* group) const
{
    if (!group)
        return BoundingBoxf3();

    BoundingBoxf3 bb;
    for (const ModelVolume* vol : group->volumes) {
        bb.merge(vol->get_convex_hull().bounding_box());
    }
    return bb;
}
```

---

### Step 4.2: Render Group Bounding Box

**File:** `src/slic3r/GUI/GLCanvas3D.cpp`

**Find:** The rendering loop where selection bounding boxes are drawn

**Add:** Group bounding box rendering

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
    glsafe(::glEnable(GL_LINE_STIPPLE));
    glsafe(::glLineStipple(1, 0x0F0F));  // Dashed pattern
    glsafe(::glLineWidth(2.0f));

    // Set color to blue for group bounding box
    const ColorRGBA color(0.0f, 0.5f, 1.0f, 0.8f);

    // Render the box edges
    render_bounding_box_edges(box, color);

    glsafe(::glDisable(GL_LINE_STIPPLE));
}
```

**Add call in main render loop:**

```cpp
void GLCanvas3D::render()
{
    // ... existing render code ...

    // Orca: Render group bounding box if group selected
    render_group_bounding_box();

    // ... rest of render code ...
}
```

---

### Step 4.3: Handle Group Selection from ObjectList

**File:** `src/slic3r/GUI/GUI_ObjectList.cpp`

**Find:** The method that handles item selection in the tree (search for "OnSelectionChanged" or similar)

**Add:** Group selection handling

```cpp
void ObjectList::selection_changed()
{
    if (m_prevent_list_events)
        return;

    const auto item = GetSelection();
    if (!item.IsOk())
        return;

    const ItemType type = m_objects_model->GetItemType(item);

    // Orca: Handle group selection
    if (type == itVolumeGroup) {
        int obj_idx = m_objects_model->GetObjectIdByItem(item);
        int group_id = m_objects_model->GetVolumeIdByItem(item);

        auto obj = (*m_objects)[obj_idx];
        ModelVolumeGroup* group = obj->get_volume_group_by_id(group_id);

        if (group) {
            // Select group in 3D view
            wxGetApp().plater()->canvas3D()->get_selection().add_volume_group(group);
            return;
        }
    }

    // ... existing selection handling for other types ...
}
```

---

## Phase 5: Group Properties Panel

### Goal
Show editable group properties when a group is selected in the object list.

### Step 5.1: Detect Group Selection

**File:** `src/slic3r/GUI/GUI_ObjectSettings.cpp`

**Find:** The method that updates the settings panel (search for "update_settings_list" or "show_settings")

**Add:** Group settings handling

```cpp
bool ObjectSettings::update_settings_list()
{
    // ... existing code ...

    const auto item = obj_list()->GetSelection();
    if (!item.IsOk())
        return false;

    const ItemType type = obj_list()->get_model()->GetItemType(item);

    // Orca: Handle group selection
    if (type == itVolumeGroup) {
        int obj_idx = obj_list()->get_model()->GetObjectIdByItem(item);
        int group_id = obj_list()->get_model()->GetVolumeIdByItem(item);

        auto obj = (*obj_list()->objects())[obj_idx];
        ModelVolumeGroup* group = obj->get_volume_group_by_id(group_id);

        if (group) {
            show_group_settings(group);
            return true;
        }
    }

    // ... existing code for other types ...
}
```

---

### Step 5.2: Group Properties UI

**File:** `src/slic3r/GUI/GUI_ObjectSettings.cpp`

**Add:** Group settings panel

```cpp
void ObjectSettings::show_group_settings(ModelVolumeGroup* group)
{
    if (!group)
        return;

    clear_settings();

    wxBoxSizer* sizer = new wxBoxSizer(wxVERTICAL);

    // Group name
    wxStaticText* name_label = new wxStaticText(this, wxID_ANY, _L("Group name:"));
    wxTextCtrl* name_ctrl = new wxTextCtrl(this, wxID_ANY, from_u8(group->name));
    name_ctrl->Bind(wxEVT_TEXT, [this, group](wxCommandEvent& e) {
        group->name = e.GetString().ToStdString();
        obj_list()->update_name_in_list(group);
        obj_list()->part_selection_changed();
    });

    wxBoxSizer* name_sizer = new wxBoxSizer(wxHORIZONTAL);
    name_sizer->Add(name_label, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 5);
    name_sizer->Add(name_ctrl, 1, wxEXPAND);
    sizer->Add(name_sizer, 0, wxEXPAND | wxALL, 5);

    // Extruder selection
    wxStaticText* extruder_label = new wxStaticText(this, wxID_ANY, _L("Extruder:"));

    wxArrayString extruder_choices;
    extruder_choices.Add(_L("Use volume extruder"));
    for (int i = 0; i < extruders_count(); ++i) {
        extruder_choices.Add(wxString::Format("Extruder %d", i + 1));
    }

    wxChoice* extruder_choice = new wxChoice(this, wxID_ANY,
                                             wxDefaultPosition, wxDefaultSize,
                                             extruder_choices);
    extruder_choice->SetSelection(group->extruder_id + 1);
    extruder_choice->Bind(wxEVT_CHOICE, [this, group](wxCommandEvent& e) {
        group->extruder_id = e.GetSelection() - 1;
        obj_list()->update_extruder_in_list(group);
        wxGetApp().plater()->update();
    });

    wxBoxSizer* extruder_sizer = new wxBoxSizer(wxHORIZONTAL);
    extruder_sizer->Add(extruder_label, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 5);
    extruder_sizer->Add(extruder_choice, 1, wxEXPAND);
    sizer->Add(extruder_sizer, 0, wxEXPAND | wxALL, 5);

    // Visible checkbox
    wxCheckBox* visible_check = new wxCheckBox(this, wxID_ANY, _L("Visible"));
    visible_check->SetValue(group->visible);
    visible_check->Bind(wxEVT_CHECKBOX, [this, group](wxCommandEvent& e) {
        group->visible = e.IsChecked();
        wxGetApp().plater()->update();
    });
    sizer->Add(visible_check, 0, wxALL, 5);

    // Volume count info
    wxString info = wxString::Format(_L("Contains %d volumes"), (int)group->volume_count());
    wxStaticText* info_label = new wxStaticText(this, wxID_ANY, info);
    sizer->Add(info_label, 0, wxALL, 5);

    // Help text
    wxStaticText* help = new wxStaticText(this, wxID_ANY,
        _L("Groups allow organizing multiple volumes.\n"
           "All volumes in a group can share the same extruder."));
    help->Wrap(200);
    sizer->Add(help, 0, wxALL, 10);

    this->SetSizer(sizer);
    Layout();
}
```

---

## Integration Checklist

### Before Testing:

- [ ] Add itVolumeGroup to ItemType enum ✅ (Already done)
- [ ] Implement ObjectDataViewModel group methods
- [ ] Add group context menu items
- [ ] Implement group operations (create, ungroup, delete)
- [ ] Add group selection to Selection class
- [ ] Render group bounding box
- [ ] Add group properties panel

### Testing Steps:

1. **Create Group:**
   - [ ] Load object with multiple volumes
   - [ ] Select 2+ volumes
   - [ ] Right-click → "Create group from selection"
   - [ ] Verify group appears in tree
   - [ ] Verify volumes nested under group

2. **Rename Group:**
   - [ ] Select group
   - [ ] Change name in properties panel
   - [ ] Verify name updates in tree

3. **Set Group Extruder:**
   - [ ] Select group
   - [ ] Change extruder in properties panel
   - [ ] Verify extruder indicator updates
   - [ ] Slice and check G-code

4. **Ungroup:**
   - [ ] Select group
   - [ ] Right-click → "Ungroup"
   - [ ] Verify volumes move to root level
   - [ ] Verify group deleted

5. **Group Selection:**
   - [ ] Click group in tree
   - [ ] Verify all volumes highlighted in 3D view
   - [ ] Verify blue dashed bounding box appears

6. **Serialization:**
   - [ ] Create groups
   - [ ] Save project
   - [ ] Reload project
   - [ ] Verify groups intact

---

## Estimated Completion Time

- **Phase 3 (ObjectList):** 2-3 hours
- **Phase 4 (Selection):** 1 hour
- **Phase 5 (Properties):** 1 hour
- **Testing & Debugging:** 1-2 hours
- **Total:** 5-7 hours

---

## Key Files to Modify

| File | Purpose | Est. Lines |
|------|---------|------------|
| `ObjectDataViewModel.cpp` | Add group tree nodes | ~100 |
| `GUI_ObjectList.cpp` | Context menus & operations | ~200 |
| `Selection.hpp` | Group selection interface | ~10 |
| `Selection.cpp` | Group selection logic | ~70 |
| `GLCanvas3D.cpp` | Render group bbox | ~30 |
| `GUI_ObjectSettings.cpp` | Group properties panel | ~80 |
| **Total** | | **~490 lines** |

---

## Tips for Implementation

1. **Start Small:** Implement group display in tree first, then add operations
2. **Follow Patterns:** Look at how volumes are handled and copy that pattern for groups
3. **Test Incrementally:** Test each operation as you implement it
4. **Use Existing Icons:** Reuse folder or volume icons for groups initially
5. **Error Handling:** Add null checks for all group pointers
6. **Undo/Redo:** Consider adding undo support for group operations later

---

## Known Challenges

1. **Tree Refresh:** May need to fully rebuild tree after group operations
2. **Drag-Drop:** Dragging volumes into/out of groups would be nice but complex
3. **Nested Groups:** Current design doesn't support groups within groups
4. **Volume Deletion:** Deleting a volume should update its group
5. **Multi-Selection:** Selecting multiple groups simultaneously needs careful handling

---

## Future Enhancements

1. **Drag-and-Drop:** Drag volumes into/out of groups
2. **Group Icons:** Custom icon showing group type
3. **Group Colors:** Color-code groups for visual distinction
4. **Collapse/Expand:** Collapsible group nodes in tree
5. **Group Templates:** Save/load group configurations

---

## Conclusion

The backend for Feature #5 is complete and tested. This guide provides a clear roadmap for the GUI implementation. Each phase builds on the previous one, allowing incremental development and testing.

The implementation follows OrcaSlicer's existing patterns for object list management, selection handling, and properties display, ensuring consistency with the rest of the application.
