# User Guide: Hierarchical Object Grouping in OrcaSlicer

**Feature:** Hierarchical Volume Grouping
**Version:** 1.0
**Date:** 2026-02-13

---

## Table of Contents

1. [Overview](#overview)
2. [What Are Volume Groups?](#what-are-volume-groups)
3. [Why Use Groups?](#why-use-groups)
4. [Getting Started](#getting-started)
5. [Creating Groups](#creating-groups)
6. [Managing Groups](#managing-groups)
7. [Assigning Extruders to Groups](#assigning-extruders-to-groups)
8. [Ungrouping Volumes](#ungrouping-volumes)
9. [Working with Groups in 3D View](#working-with-groups-in-3d-view)
10. [Saving and Loading Projects](#saving-and-loading-projects)
11. [Advanced Tips](#advanced-tips)
12. [Troubleshooting](#troubleshooting)
13. [FAQs](#faqs)

---

## Overview

Hierarchical Object Grouping allows you to organize multiple volumes within an object into named groups. This feature helps manage complex multi-part assemblies and simplifies extruder assignment for multi-material printing.

---

## What Are Volume Groups?

A **Volume Group** is a logical collection of volumes within a single object. Think of it as a folder that contains related parts:

```
Object: Robot Model
├── Group: Body Parts
│   ├── Volume: Torso
│   ├── Volume: Head
│   └── Volume: Backplate
├── Group: Arms
│   ├── Volume: Left Arm
│   └── Volume: Right Arm
└── Volume: Base (ungrouped)
```

### Key Features

- **Organization:** Keep related volumes together
- **Extruder Assignment:** Assign one extruder to an entire group
- **Visual Clarity:** See structure at a glance in the object list
- **Batch Operations:** Manage multiple volumes as one unit

---

## Why Use Groups?

### Use Case 1: Complex Assemblies

**Before Groups:**
```
Object: Articulated Figure (20 volumes)
├── Volume: Torso Front
├── Volume: Torso Back
├── Volume: Head Shell
├── Volume: Head Face
├── Volume: Left Leg Upper
├── Volume: Left Leg Lower
... (14 more volumes)
```

Difficult to navigate, hard to see structure, easy to lose track of which parts belong together.

**After Groups:**
```
Object: Articulated Figure
├── Group: Body (3 volumes)
├── Group: Head (2 volumes)
├── Group: Left Leg (4 volumes)
├── Group: Right Leg (4 volumes)
├── Group: Left Arm (3 volumes)
└── Group: Right Arm (4 volumes)
```

Clear structure, easy to navigate, obvious organization.

### Use Case 2: Multi-Material Printing

**Scenario:** Printing a dual-color logo with support material

**Without Groups:**
- Select Logo Volume 1 → Set Extruder 1
- Select Logo Volume 2 → Set Extruder 1
- Select Logo Volume 3 → Set Extruder 1
- Select Border Volume 1 → Set Extruder 2
- Select Border Volume 2 → Set Extruder 2
- Select Support → Set Extruder 3

**With Groups:**
- Create "Logo" group → Set Extruder 1
- Create "Border" group → Set Extruder 2
- Support remains Extruder 3

**Result:** Fewer clicks, clearer intent, easier to modify later.

### Use Case 3: Iterative Design

**Scenario:** Testing different part variations

```
Object: Phone Case Design
├── Group: Base Design (always print)
│   ├── Volume: Main Shell
│   └── Volume: Button Cutouts
├── Group: Variant A - Grip Texture
│   ├── Volume: Textured Surface
│   └── Volume: Ridge Pattern
└── Group: Variant B - Smooth Finish
    └── Volume: Smooth Surface
```

Easily hide/show different variants without deleting volumes.

---

## Getting Started

### Prerequisites

- OrcaSlicer with Hierarchical Grouping feature
- An object with at least 2 volumes
- Familiarity with the object list panel

### Basic Workflow

1. Load or create an object with multiple volumes
2. Select volumes you want to group
3. Right-click → "Create group from selection"
4. Name your group
5. Assign extruder if needed (multi-material)
6. Save your project

---

## Creating Groups

### Method 1: From Selection (Most Common)

**Step-by-Step:**

1. **Select Volumes**
   - Click first volume in object list
   - Hold Ctrl and click additional volumes
   - All selected volumes must be from the same object

2. **Create Group**
   - Right-click on any selected volume
   - Choose "Create group from selection"

3. **Name Your Group**
   - Dialog appears: "Enter group name:"
   - Type a descriptive name (e.g., "Front Panel")
   - Click OK

4. **Result**
   - New group appears in object list
   - Selected volumes now nested under group
   - Group automatically selected

**Example:**
```
Before:
Object
├── Volume: Part A
├── Volume: Part B
├── Volume: Part C
└── Volume: Part D

Select Parts A, B, C → Create Group "Main Assembly"

After:
Object
├── Group: Main Assembly
│   ├── Volume: Part A
│   ├── Volume: Part B
│   └── Volume: Part C
└── Volume: Part D
```

### Method 2: Iterative Grouping

You can create multiple groups in one object:

**Example Workflow:**

1. Select Volume 1, 2, 3 → Create Group "Body"
2. Select Volume 4, 5 → Create Group "Arms"
3. Select Volume 6, 7, 8 → Create Group "Legs"
4. Leave Volume 9 ungrouped (base plate)

**Result:**
```
Object: Action Figure
├── Group: Body (3 volumes)
├── Group: Arms (2 volumes)
├── Group: Legs (3 volumes)
└── Volume: Base Plate
```

### Requirements and Limitations

✅ **Allowed:**
- Minimum 2 volumes to create a group
- Multiple groups in one object
- Descriptive group names (any characters except illegal filename chars)
- Volumes can be moved between groups (ungroup + regroup)

❌ **Not Allowed:**
- Groups containing only 1 volume (minimum 2 required)
- Volumes from different objects in same group
- Nested groups (groups inside groups)
- Empty groups

---

## Managing Groups

### Renaming Groups

**Method 1: Context Menu**
1. Right-click group in object list
2. Select "Rename"
3. Enter new name
4. Click OK

**Method 2: Double-Click** (if supported)
1. Double-click group name
2. Type new name
3. Press Enter

**Tips:**
- Use descriptive names: "Leg Assembly" not "Group 1"
- Avoid illegal characters: `< > : " / \ | ? *`
- Names can include spaces and numbers

### Deleting Groups

**Option 1: Delete Group AND Volumes**
1. Right-click group
2. Select "Delete group"
3. **Warning:** Both group and all contained volumes are deleted!

**Option 2: Ungroup (Preserve Volumes)**
1. Right-click group
2. Select "Ungroup"
3. Confirm dialog
4. Volumes move to object root level
5. Group deleted, volumes preserved

**Choose Wisely:**
- Use "Ungroup" if you want to keep the volumes
- Use "Delete group" only if you want to remove everything

### Moving Volumes Between Groups

**Current Method:**
1. Select group containing volume
2. Right-click → "Ungroup"
3. Select freed volumes + other volumes
4. Right-click → "Create group from selection"

**Future Enhancement:** Drag-and-drop between groups (planned)

---

## Assigning Extruders to Groups

### Overview

In multi-material printing, each volume can use a different extruder/filament. Groups allow you to assign one extruder to all volumes in the group at once.

### How It Works

**Extruder Priority:**
1. **Volume-specific:** If a volume has an extruder assigned, it uses that
2. **Group-level:** If no volume assignment, uses group's extruder
3. **Object-level:** If no group assignment, uses object's default
4. **Global:** If nothing assigned, uses first extruder

### Assigning Extruder to Group

**Step-by-Step:**

1. **Select Group**
   - Click group in object list

2. **Open Extruder Menu**
   - Right-click group
   - Hover over "Set extruder"
   - Submenu appears

3. **Choose Extruder**
   - "Default" - Inherit from object/global settings
   - "Extruder 1" - Use first extruder/filament
   - "Extruder 2" - Use second extruder/filament
   - (etc. for additional extruders)

4. **Verify Assignment**
   - Group name shows extruder badge: "Main Body [2]"
   - Means all volumes in group will use Extruder 2

### Example Scenario

**Object:** Dual-Color Trophy

**Setup:**
```
Object: Trophy
├── Group: Base [Extruder 1 - Gold PLA]
│   ├── Volume: Platform
│   ├── Volume: Column
│   └── Volume: Plinth
└── Group: Top [Extruder 2 - Silver PLA]
    ├── Volume: Cup
    ├── Volume: Handles (Left)
    └── Volume: Handles (Right)
```

**Workflow:**
1. Create "Base" group → Right-click → Set extruder → Extruder 1
2. Create "Top" group → Right-click → Set extruder → Extruder 2
3. Slice
4. G-code uses T0 for base, T1 for top

**Result:** Clean color separation without assigning extruder to each individual volume.

### Override Individual Volumes

If one volume in a group needs a different extruder:

1. Select the specific volume
2. Right-click → Set extruder → Choose different extruder
3. Volume now has its own assignment (overrides group)

**Example:**
```
Group: Body [Extruder 1]
├── Volume: Shell (uses Extruder 1 from group)
├── Volume: Button [Extruder 2 override]
└── Volume: Panel (uses Extruder 1 from group)
```

---

## Ungrouping Volumes

### When to Ungroup

- You want to reorganize volumes differently
- You no longer need the grouping structure
- You want to delete only the group, not the volumes

### Ungroup Operation

**Step-by-Step:**

1. **Select Group**
   - Click group in object list

2. **Initiate Ungroup**
   - Right-click group
   - Select "Ungroup"

3. **Confirm**
   - Dialog: "Ungroup 'Group Name'? Volumes will remain but group will be deleted."
   - Click "Yes" to proceed
   - Click "No" to cancel

4. **Result**
   - Group removed from object list
   - Volumes move to object root level
   - All volumes preserved
   - Extruder assignments on volumes preserved

**Example:**
```
Before Ungroup:
Object
├── Group: Assembly
│   ├── Volume: Part A
│   ├── Volume: Part B
│   └── Volume: Part C
└── Volume: Base

After Ungroup:
Object
├── Volume: Part A
├── Volume: Part B
├── Volume: Part C
└── Volume: Base
```

### Undo Support

If you ungroup accidentally:
- Press Ctrl+Z (Windows/Linux) or Cmd+Z (Mac)
- Group will be restored with all volumes

---

## Working with Groups in 3D View

### Selecting Groups

**From Object List:**
- Click group in object list
- All volumes in group selected in 3D view
- Cyan bounding box drawn around entire group

**Visual Indicators:**
- Regular selection: White/yellow bounding box
- Group selection: Cyan bounding box (distinctive color)

### Group Bounding Box

The cyan bounding box encompasses all volumes in the group:

```
┌─────────────────────────┐
│  ╔═══════════════════╗  │ ← Cyan group box
│  ║ Part A            ║  │
│  ║ Part B            ║  │
│  ║ Part C            ║  │
│  ╚═══════════════════╝  │
└─────────────────────────┘
```

### Using Gizmos with Groups

When a group is selected, gizmos affect all volumes:

**Move Gizmo:** Moves all volumes in group together
**Rotate Gizmo:** Rotates all volumes around group center
**Scale Gizmo:** Scales all volumes proportionally

**Note:** Individual volume transformations are preserved.

---

## Saving and Loading Projects

### 3MF File Format

Groups are saved in the 3MF project file using a custom extension:

```xml
<volumegroups>
  <group id="1" name="Body Parts" extruder="0" visible="1">
    <volume refid="0"/>
    <volume refid="1"/>
    <volume refid="2"/>
  </group>
  <group id="2" name="Arms" extruder="1" visible="1">
    <volume refid="3"/>
    <volume refid="4"/>
  </group>
</volumegroups>
```

### Saving Projects

**All Group Data Saved:**
- Group names
- Group IDs
- Extruder assignments
- Volume membership
- Visibility state

**Workflow:**
1. File → Save Project (or Ctrl+S)
2. Choose location and filename
3. Click Save
4. Groups are automatically included

### Loading Projects

**Opening Saved Projects:**
1. File → Open Project (or Ctrl+O)
2. Select .3mf file
3. Click Open
4. Groups restore exactly as saved

**Verification:**
- Check object list shows groups
- Verify extruder badges correct
- Confirm volumes nested properly

### Backward Compatibility

**Loading Old Files:**
- Old .3mf files (before grouping feature) open normally
- No groups present, but everything else works

**Forward Compatibility:**
- New .3mf files (with groups) open in updated OrcaSlicer
- Groups fully functional

**Old Version Compatibility:**
- Opening new .3mf in old OrcaSlicer: Groups ignored, volumes load
- No errors, just no group structure

---

## Advanced Tips

### Tip 1: Naming Conventions

Use consistent naming for better organization:

**Functional Naming:**
- "Structural Parts"
- "Decorative Elements"
- "Support Attachments"

**Positional Naming:**
- "Front Panel"
- "Left Side Assembly"
- "Top Cover"

**Material/Color Naming:**
- "Gold Filament Parts"
- "Transparent Windows"
- "Black Base"

### Tip 2: Color-Coding with Extruders

Assign extruders to groups to match your physical filament colors:

```
Object: Rainbow Model
├── Group: Red Parts [Extruder 1 - Red PLA]
├── Group: Blue Parts [Extruder 2 - Blue PLA]
├── Group: Green Parts [Extruder 3 - Green PLA]
└── Group: Yellow Parts [Extruder 4 - Yellow PLA]
```

### Tip 3: Iterative Design Workflow

Use groups to manage design iterations:

**Setup:**
```
Object: Product Prototype
├── Group: Base (Common to all versions)
├── Group: Version A - Rounded Edges
├── Group: Version B - Sharp Angles
└── Group: Version C - Hybrid Design
```

**Workflow:**
1. Print with Base + Version A
2. Test
3. Hide Version A, show Version B
4. Print with Base + Version B
5. Compare results

### Tip 4: Assembly Instructions

Group names can serve as assembly hints:

```
Object: Furniture Kit
├── Group: 1 - Frame (assemble first)
├── Group: 2 - Panels (attach to frame)
├── Group: 3 - Doors (final step)
└── Volume: Hardware (separate print)
```

### Tip 5: Multi-Plate Projects

Organize different plates using groups:

**Plate 1:**
```
Object: Full Assembly
├── Group: Main Body (all volumes)
```

**Plate 2:**
```
Object: Full Assembly
├── Group: Replacement Parts (subset)
```

---

## Troubleshooting

### Problem: Can't Create Group

**Symptom:** "Create group from selection" option is disabled/missing

**Possible Causes:**
1. Less than 2 volumes selected
2. Volumes from different objects selected
3. Non-volume items selected (instances, settings, etc.)

**Solutions:**
- Ensure at least 2 volumes selected
- Check all selections are from same object
- Only select volume items (not object, instance, or settings)

### Problem: Group Not Showing in Tree

**Symptom:** Created group, but don't see it in object list

**Possible Causes:**
1. Parent object collapsed
2. UI refresh needed
3. Group creation failed silently

**Solutions:**
- Click the arrow next to object name to expand
- Press F5 or click away and back to object list
- Try creating group again with valid selection

### Problem: Extruder Assignment Not Working

**Symptom:** Sliced with group extruder, but G-code uses different extruder

**Possible Causes:**
1. Volume has specific extruder override
2. Object has conflicting setting
3. Print settings override group assignment

**Solutions:**
- Check individual volume extruder settings
- Remove volume-specific extruder assignments
- Verify print settings allow per-volume extruders

### Problem: Can't Ungroup

**Symptom:** "Ungroup" option missing or disabled

**Possible Causes:**
1. Not a group item selected
2. Group selected but menu bug
3. Group already ungrouped

**Solutions:**
- Verify you selected a group (not volume)
- Check group item type in object list
- Restart OrcaSlicer if menu doesn't appear

### Problem: Lost Groups After Save/Load

**Symptom:** Saved project with groups, but groups missing after reload

**Possible Causes:**
1. Didn't save after creating groups
2. Opened file in old OrcaSlicer version
3. File corruption

**Solutions:**
- Always save after creating groups
- Ensure using OrcaSlicer with grouping feature
- Try "Save As" with new filename

### Problem: Group Selection Selects Wrong Volumes

**Symptom:** Click group, but different volumes selected in 3D view

**Possible Causes:**
1. Volume membership changed
2. 3D view out of sync
3. Multiple instances of object

**Solutions:**
- Refresh 3D view (F5)
- Check volume membership in group
- Verify correct object instance selected

---

## FAQs

### Q1: Can groups contain other groups (nested groups)?

**A:** No, groups can only contain volumes directly. Nesting groups inside groups is not currently supported.

**Workaround:** Use descriptive naming to imply hierarchy:
```
Object
├── Group: Body - Main
├── Group: Body - Details
├── Group: Arms - Left
└── Group: Arms - Right
```

### Q2: Can I drag volumes into/out of groups?

**A:** Not yet. Drag-and-drop is a planned enhancement. Currently, use the ungroup/regroup workflow.

### Q3: Do groups affect slicing performance?

**A:** No, groups are organizational only. Slicing performance is the same as without groups.

### Q4: Can I export groups to STL/OBJ?

**A:** When exporting to STL/OBJ, groups are not preserved (these formats don't support metadata). Only the geometry is exported.

**Tip:** Export as 3MF to preserve groups.

### Q5: Can I share grouped projects with others?

**A:** Yes! Save as .3mf and share the file. Anyone with OrcaSlicer (with grouping feature) will see the groups.

**Note:** If they open in old OrcaSlicer, groups won't show but volumes will load fine.

### Q6: How many groups can I create?

**A:** No hard limit. Practical limit depends on your object complexity and UI responsiveness. Tested with 20+ groups without issues.

### Q7: Can I assign different print settings to groups?

**A:** Groups don't have their own print settings. However, you can:
- Assign extruders to groups (multi-material)
- Assign settings to individual volumes in group
- Settings inherit normally

### Q8: Do groups work with mirrored/cloned objects?

**A:** Yes. When you clone or mirror an object, the group structure is preserved in the copy.

### Q9: Can I use groups with instance modifiers?

**A:** Yes. Groups are independent of instances. Each instance of an object shares the same group structure.

### Q10: Are groups visible in G-code?

**A:** No, groups are organizational only and don't appear in G-code. The G-code generator uses the volume-level settings (which may inherit from groups).

---

## Best Practices Summary

### DO:
✅ Use descriptive group names
✅ Group by function, location, or material
✅ Assign extruders at group level for multi-material
✅ Save projects as .3mf to preserve groups
✅ Use groups for complex assemblies (10+ volumes)
✅ Create consistent naming conventions

### DON'T:
❌ Create groups with only 1 volume
❌ Use generic names like "Group 1", "Group 2"
❌ Mix volumes from different objects in one group
❌ Forget to save after creating groups
❌ Delete groups when you mean to ungroup
❌ Over-organize simple models

---

## Keyboard Shortcuts

*Note: Shortcuts may vary by platform*

| Action | Windows/Linux | macOS |
|--------|---------------|-------|
| Undo | Ctrl+Z | Cmd+Z |
| Redo | Ctrl+Y | Cmd+Shift+Z |
| Save | Ctrl+S | Cmd+S |
| Refresh View | F5 | F5 |
| Select Multiple | Ctrl+Click | Cmd+Click |

*Group-specific shortcuts may be added in future versions*

---

## Getting Help

### Documentation
- This user guide
- OrcaSlicer Wiki: [link]
- Video tutorials: [link]

### Community Support
- OrcaSlicer Discord: [link]
- Reddit: r/OrcaSlicer
- GitHub Issues: [link]

### Reporting Bugs
If you encounter issues with groups:
1. GitHub Issues: https://github.com/OrcaSlicer/OrcaSlicer/issues
2. Include:
   - OrcaSlicer version
   - Steps to reproduce
   - Screenshots of object list
   - Sample .3mf file (if possible)

---

## Version History

### Version 1.0 (2026-02-13)
- Initial release of Hierarchical Object Grouping
- Create groups from selection
- Rename groups
- Assign extruders to groups
- Ungroup operation
- Delete groups
- 3MF serialization support
- 3D view selection synchronization

### Planned Features
- Drag-and-drop volume management
- Group-level print settings
- Nested groups (groups in groups)
- Group templates
- Batch operations on multiple groups
- Custom group icons

---

**End of User Guide**

*For technical documentation, see:*
- `feature5-phase5-completion.md` - Implementation details
- `code-validation-report.md` - Technical validation
- `final-implementation-summary.md` - Project overview
