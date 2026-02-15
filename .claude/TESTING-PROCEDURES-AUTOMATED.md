# OrcaSlicer Feature Testing Procedures
**Created:** 2026-02-14
**Purpose:** Step-by-step testing instructions for all 6 custom features

---

## 🎯 Testing Overview

**Total Features:** 6
**Estimated Testing Time:** 30-45 minutes
**Prerequisites:**
- orca-slicer.exe built successfully
- Application launches without errors
- Basic test models available (cube, cylinder, benchy)

---

## 📋 Test Checklist

### Pre-Testing Setup
- [ ] Application launches successfully
- [ ] No immediate console errors
- [ ] Can load simple STL file
- [ ] Main UI elements visible and responsive

### Feature Tests
- [ ] Feature #1: Per-Filament Retraction (existing - baseline test)
- [ ] Feature #2: Per-Plate Settings
- [ ] Feature #3: Prime Tower Filament Selection
- [ ] Feature #4: Support/Infill Flush Selection
- [ ] Feature #5: Hierarchical Volume Grouping
- [ ] Feature #6: Cutting Plane Adjustability

### Integration Tests
- [ ] Multiple features used together
- [ ] Save/load complex project
- [ ] No crashes or memory leaks
- [ ] Performance acceptable

---

## 🧪 TEST #1: Per-Filament Retraction (Baseline)

**Purpose:** Verify existing feature still works (regression test)

**File:** `src/libslic3r/PrintConfig.cpp` (lines 6274-6277)

**Steps:**
1. Launch OrcaSlicer
2. Go to Filament Settings
3. Look for "Enable" checkbox under Retraction section
4. Verify checkbox exists and is functional
5. Toggle checkbox on/off
6. Change retraction length value
7. Save filament preset
8. Load preset again
9. Verify settings persisted

**Success Criteria:**
- ✓ Retraction enable checkbox visible
- ✓ Can toggle on/off
- ✓ Can change retraction parameters
- ✓ Settings save and load correctly
- ✓ No crashes or errors

**If Failed:**
- Check console for errors
- Verify PrintConfig.cpp:6274-6277 not modified incorrectly
- Check filament preset file format

---

## 🧪 TEST #2: Per-Plate Settings ⭐ MAJOR FEATURE

**Purpose:** Verify per-plate printer and filament preset selection

**Files:**
- `src/slic3r/GUI/PartPlate.hpp` (lines 169-171, 306-329)
- `src/slic3r/GUI/PartPlate.cpp` (lines 2344-2532)
- `src/slic3r/GUI/Plater.cpp` (lines 3715-3744, 3843-3855)

**Test Steps:**

### Test 2.1: Basic Plate Settings Dialog
1. Create new project
2. Add a simple cube (20x20x20mm)
3. Right-click on Plate 1 in plate list
4. Look for "Plate Settings..." context menu option
5. Click "Plate Settings..."
6. Verify dialog opens

**Expected Results:**
- ✓ Context menu shows "Plate Settings..." option
- ✓ Dialog opens without crash
- ✓ Dialog shows current printer preset
- ✓ Dialog shows current filament presets

**If Dialog Doesn't Open:**
- Check Plater.cpp:3715-3744 (context menu binding)
- Check for errors in console
- Verify PartPlate.cpp:2344-2532 (dialog implementation)

### Test 2.2: Change Printer Preset
1. Open Plate Settings dialog
2. Note current printer preset name
3. Click printer dropdown
4. Select different printer preset
5. Click OK
6. Verify plate updates

**Expected Results:**
- ✓ Printer dropdown shows available presets
- ✓ Can select different preset
- ✓ Dialog closes without error
- ✓ Plate uses new preset (check build volume visualization)

### Test 2.3: Change Filament Presets
1. Open Plate Settings dialog
2. For single-extruder: See one filament dropdown
3. For multi-extruder: See multiple filament dropdowns
4. Change filament preset(s)
5. Click OK

**Expected Results:**
- ✓ Filament dropdowns show available presets
- ✓ Can select different presets
- ✓ Number of dropdowns matches extruder count
- ✓ Changes apply correctly

### Test 2.4: Save and Load Project
1. Set up custom presets for a plate
2. Add objects to that plate
3. Save project as 3MF
4. Close OrcaSlicer
5. Reopen OrcaSlicer
6. Load the 3MF file
7. Check plate settings

**Expected Results:**
- ✓ Project saves without error
- ✓ Project loads without error
- ✓ Per-plate printer preset restored
- ✓ Per-plate filament presets restored
- ✓ Objects still on correct plates

**Critical Code Points to Check if Failed:**
- `PartPlate.cpp:2344-2398` - Dialog creation
- `PartPlate.cpp:2473-2502` - Config building (build_plate_config)
- `PartPlate.cpp:2504-2531` - Validation
- `Plater.cpp:3715-3744` - Context menu integration
- 3MF save/load serialization

---

## 🧪 TEST #3: Prime Tower Filament Selection

**Purpose:** Verify prime tower can use subset of filaments

**File:** `src/libslic3r/PrintConfig.cpp` (lines 6278-6293)

**Test Steps:**

### Test 3.1: Setting Visibility
1. Launch OrcaSlicer
2. Set up multi-material print (2+ filaments)
3. Go to Print Settings
4. Navigate to Multi-material section
5. Look for "Prime Tower Filaments" setting
6. Verify setting is visible

**Expected Results:**
- ✓ "Prime Tower Filaments" setting exists
- ✓ Setting shows list of available filaments
- ✓ Can check/uncheck individual filaments
- ✓ At least one filament must be selected

**If Setting Not Visible:**
- Check PrintConfig.cpp:6278-6293
- Verify def->label is set correctly
- Check GUI config option mapping

### Test 3.2: Functional Test
1. Set up 3-color multi-material print
2. Open Print Settings
3. Find "Prime Tower Filaments"
4. Select only filaments 1 and 3 (deselect 2)
5. Slice project
6. Examine G-code

**Expected Results:**
- ✓ Slicing completes successfully
- ✓ Prime tower generated
- ✓ Only selected filaments used in prime tower
- ✓ G-code shows correct tool changes

**G-code Verification:**
```gcode
; Look for prime tower tool changes
; Should only see T0 and T2 (filaments 1 and 3)
; Should NOT see T1 (filament 2)
```

---

## 🧪 TEST #4: Support/Infill Flush Selection

**Purpose:** Verify flush targets for support and infill

**File:** `src/libslic3r/PrintConfig.cpp` (lines 6295-6336)

**Test Steps:**

### Test 4.1: Setting Visibility
1. Set up multi-material print
2. Add supports to object
3. Go to Print Settings
4. Look for "Support Material Flush Filaments"
5. Look for "Sparse Infill Flush Filaments"

**Expected Results:**
- ✓ "Support Material Flush Filaments" exists
- ✓ "Sparse Infill Flush Filaments" exists
- ✓ Both show filament checkboxes
- ✓ Can select multiple filaments for each

### Test 4.2: Support Flush Test
1. Multi-material part with supports
2. Select specific filaments for support flush
3. Slice project
4. Check G-code for support regions

**Expected Results:**
- ✓ Slicing succeeds
- ✓ Support flush only to selected filaments
- ✓ G-code shows correct purge behavior

### Test 4.3: Infill Flush Test
1. Multi-material part with infill
2. Select specific filaments for infill flush
3. Slice project
4. Check G-code for infill regions

**Expected Results:**
- ✓ Slicing succeeds
- ✓ Infill flush only to selected filaments
- ✓ G-code shows correct purge behavior

---

## 🧪 TEST #5: Hierarchical Volume Grouping ⭐ MAJOR FEATURE

**Purpose:** Verify group/ungroup operations on volumes

**Files:**
- `src/libslic3r/Model.hpp` (lines 104-145, 599-631)
- `src/libslic3r/Model.cpp` (lines 2081-2373)
- `src/slic3r/GUI/GUI_ObjectList.hpp` (lines 87-94)
- `src/slic3r/GUI/GUI_ObjectList.cpp` (lines 340-575, 653-676, 744-1219, 1305-1315, 3033-3042)
- `src/slic3r/GUI/Plater.cpp` (lines 3603-3636)

**Test Steps:**

### Test 5.1: Create Group
1. Load project with single object
2. Add 2+ volumes to object (modifiers or parts)
3. In object list, select 2 volumes
4. Right-click on selection
5. Look for "Group" option
6. Click "Group"

**Expected Results:**
- ✓ "Group" option appears in context menu
- ✓ Group created successfully
- ✓ Group appears in object tree
- ✓ Selected volumes moved under group
- ✓ Group has default name "Group 1"

**If Group Option Missing:**
- Check Plater.cpp:3603-3636 (context menu)
- Check GUI_ObjectList.cpp:744-1219 (group operations)
- Verify ModelVolumeGroup class in Model.hpp:104-145

### Test 5.2: Rename Group
1. With group created
2. Right-click on group
3. Select "Rename"
4. Enter new name: "Test Group"
5. Press Enter

**Expected Results:**
- ✓ Rename option appears
- ✓ Inline edit field appears
- ✓ Can type new name
- ✓ Name saves on Enter
- ✓ Group shows new name in tree

### Test 5.3: Expand/Collapse Group
1. Click arrow/triangle next to group
2. Verify volumes show/hide
3. Click again to collapse
4. Repeat several times

**Expected Results:**
- ✓ Group expands showing child volumes
- ✓ Group collapses hiding child volumes
- ✓ Expand state persists during session
- ✓ UI updates smoothly

### Test 5.4: Ungroup
1. Right-click on group
2. Select "Ungroup"
3. Verify volumes restored

**Expected Results:**
- ✓ "Ungroup" option appears
- ✓ Group removed from tree
- ✓ Volumes moved back to parent object
- ✓ Volumes retain all properties

### Test 5.5: Nested Groups
1. Create group with 2 volumes
2. Add 1 more volume to object
3. Select the group AND the loose volume
4. Create group of the group + volume
5. Verify nested structure

**Expected Results:**
- ✓ Can group a group with volumes
- ✓ Tree shows proper hierarchy
- ✓ Nested expand/collapse works
- ✓ Can ungroup at any level

### Test 5.6: Save/Load with Groups
1. Create groups with custom names
2. Save project as 3MF
3. Close OrcaSlicer
4. Reload project
5. Check groups

**Expected Results:**
- ✓ Groups save to 3MF
- ✓ Groups load from 3MF
- ✓ Group names preserved
- ✓ Hierarchy preserved
- ✓ No data loss

---

## 🧪 TEST #6: Cutting Plane Adjustability

**Purpose:** Verify cutting plane size can be adjusted

**Files:**
- `src/slic3r/GUI/Gizmos/GLGizmoCut.hpp` (lines 150-153)
- `src/slic3r/GUI/Gizmos/GLGizmoCut.cpp` (lines 85-102)

**Test Steps:**

### Test 6.1: Access Cut Tool
1. Load a simple object
2. Click Cut tool in left toolbar
3. Verify cutting plane appears
4. Look for size adjustment UI

**Expected Results:**
- ✓ Cut tool activates
- ✓ Cutting plane visible
- ✓ Plane size controls visible in UI
- ✓ Auto-size toggle visible

**If Controls Missing:**
- Check GLGizmoCut.cpp:85-102 (ImGui controls)
- Check GLGizmoCut.hpp:150-153 (member variables)
- Verify gizmo renders properly

### Test 6.2: Adjust Plane Width
1. With Cut tool active
2. Find "Plane Width" control
3. Change value (e.g., from 100 to 200)
4. Observe plane in 3D view

**Expected Results:**
- ✓ Width slider/input exists
- ✓ Can change value
- ✓ Plane width updates in real-time
- ✓ Plane centers on object

### Test 6.3: Adjust Plane Height
1. Find "Plane Height" control
2. Change value
3. Observe plane in 3D view

**Expected Results:**
- ✓ Height slider/input exists
- ✓ Can change value
- ✓ Plane height updates in real-time
- ✓ Plane stays centered

### Test 6.4: Auto-Size Toggle
1. Find "Auto-size" checkbox/toggle
2. Enable auto-size
3. Change object size or rotate
4. Observe plane adjusts automatically
5. Disable auto-size
6. Verify manual control restored

**Expected Results:**
- ✓ Auto-size toggle exists
- ✓ When enabled, plane auto-sizes to object
- ✓ When disabled, manual control works
- ✓ Toggle state persists during session

### Test 6.5: Perform Cut with Custom Size
1. Set custom plane size (e.g., 50x50mm)
2. Position plane through object
3. Click "Perform Cut"
4. Verify cut successful

**Expected Results:**
- ✓ Cut operation completes
- ✓ Two objects created
- ✓ Cut is clean and accurate
- ✓ Objects can be manipulated separately

---

## 🧪 INTEGRATION TESTS

**Purpose:** Verify features work together without conflicts

### Integration Test 1: Multi-Feature Project
1. Create multi-plate project
2. Set different presets per plate (Feature #2)
3. Add objects and create groups (Feature #5)
4. Use cut tool on grouped objects (Feature #6)
5. Set up multi-material with flush settings (Features #3, #4)
6. Save project
7. Reload project
8. Slice all plates

**Success Criteria:**
- ✓ All features work together
- ✓ No conflicts or errors
- ✓ Save/load preserves all settings
- ✓ Slicing completes successfully

### Integration Test 2: Complex Multi-Material
1. 4+ color print
2. Prime tower with subset of filaments (Feature #3)
3. Support flush to specific filaments (Feature #4)
4. Infill flush to different filaments (Feature #4)
5. Different printer for each plate (Feature #2)
6. Slice and verify G-code

**Success Criteria:**
- ✓ Configuration accepted
- ✓ Slicing completes
- ✓ G-code correct for all features
- ✓ No tool change conflicts

### Integration Test 3: Performance Test
1. Large project (10+ objects, 1000+ volumes)
2. Create deep group hierarchies (Feature #5)
3. Multiple plates with different settings (Feature #2)
4. Slice all plates
5. Monitor memory and time

**Success Criteria:**
- ✓ UI remains responsive
- ✓ Memory usage acceptable (< 4GB)
- ✓ Slicing time reasonable
- ✓ No crashes or hangs

---

## 🚨 REGRESSION TESTS

**Purpose:** Verify existing OrcaSlicer features still work

### Regression Checklist
- [ ] Load STL files
- [ ] Load 3MF files
- [ ] Add/remove objects
- [ ] Scale/rotate/move objects
- [ ] Add supports
- [ ] Change print settings
- [ ] Change printer presets
- [ ] Change filament presets
- [ ] Slice simple object
- [ ] Slice multi-material object
- [ ] Export G-code
- [ ] Preview G-code
- [ ] Camera controls (zoom, pan, rotate)
- [ ] Undo/redo operations
- [ ] Copy/paste objects
- [ ] Instance/duplicate objects

**If Any Regression Fails:**
- Document exact failure
- Check if related to our 21 modified files
- Review changes for unintended side effects
- Check git diff for accidental modifications

---

## 📊 TESTING RESULTS TEMPLATE

```markdown
# Testing Results - OrcaSlicer Custom Features
Date: 2026-02-14
Tester: Claude Code AI
Build: build-x64/OrcaSlicer/orca-slicer.exe

## Summary
- Total Tests: 30+
- Passed: ?
- Failed: ?
- Skipped: ?

## Test Results

### Feature #1: Per-Filament Retraction
Status: PASS / FAIL
Issues: None / [describe]
Notes: [observations]

### Feature #2: Per-Plate Settings
Status: PASS / FAIL
Test 2.1: PASS / FAIL
Test 2.2: PASS / FAIL
Test 2.3: PASS / FAIL
Test 2.4: PASS / FAIL
Issues: None / [describe]

### Feature #3: Prime Tower Selection
Status: PASS / FAIL
Test 3.1: PASS / FAIL
Test 3.2: PASS / FAIL
Issues: None / [describe]

### Feature #4: Support/Infill Flush
Status: PASS / FAIL
Test 4.1: PASS / FAIL
Test 4.2: PASS / FAIL
Test 4.3: PASS / FAIL
Issues: None / [describe]

### Feature #5: Hierarchical Grouping
Status: PASS / FAIL
Test 5.1: PASS / FAIL
Test 5.2: PASS / FAIL
Test 5.3: PASS / FAIL
Test 5.4: PASS / FAIL
Test 5.5: PASS / FAIL
Test 5.6: PASS / FAIL
Issues: None / [describe]

### Feature #6: Cutting Plane
Status: PASS / FAIL
Test 6.1: PASS / FAIL
Test 6.2: PASS / FAIL
Test 6.3: PASS / FAIL
Test 6.4: PASS / FAIL
Test 6.5: PASS / FAIL
Issues: None / [describe]

### Integration Tests
Test 1: PASS / FAIL
Test 2: PASS / FAIL
Test 3: PASS / FAIL

### Regression Tests
Passed: ?
Failed: ?

## Issues Found
1. [Issue description]
2. [Issue description]

## Performance Notes
- Launch time: ?s
- Memory usage: ?MB
- Slicing time (test model): ?s

## Recommendations
1. [Recommendation]
2. [Recommendation]

## Overall Assessment
[PASS / FAIL / PARTIAL]

[Detailed assessment paragraph]
```

---

## 📝 NOTES FOR TESTERS

### Testing Environment
- Windows 11 Pro 10.0.26200
- VS2026 build
- Release configuration
- All dependencies x64

### Testing Tips
1. **Document Everything:** Take screenshots of failures
2. **Test Incrementally:** Don't skip steps
3. **Check Console:** Watch for warnings/errors
4. **Memory Monitor:** Use Task Manager to watch memory
5. **Save Often:** Test save/load frequently
6. **Test Edge Cases:** Empty groups, single volume groups, etc.

### Common Issues to Watch For
- **Crashes:** Document exact steps to reproduce
- **Memory Leaks:** Long testing sessions, watch memory grow
- **UI Freezes:** Document which operation causes hang
- **Data Loss:** Verify save/load preserves all data
- **G-code Errors:** Check output is valid and correct

### Reporting Issues
For each issue found:
1. Exact steps to reproduce
2. Expected behavior
3. Actual behavior
4. Screenshots/logs
5. Files that failed (modified)
6. Console error messages

---

**Testing Procedure Created:** 2026-02-14
**Next Step:** Execute tests after successful build
**Estimated Time:** 45-60 minutes for full test suite
