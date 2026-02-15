# Creative Testing Playbook for OrcaSlicer Features
**Created:** 2026-02-14
**Purpose:** Comprehensive testing with both playful exploration and professional rigor
**Features:** All 6 custom features (1,875 lines of code)

---

## Philosophy: The Child AND The Developer

**The Child Tests:**
- "What happens if I...?"
- Breaking things to learn
- Extreme scenarios
- Fun combinations
- Artistic experiments

**The Developer Tests:**
- Edge cases and boundaries
- Data validation
- Save/load integrity
- Performance metrics
- Integration conflicts

---

# FEATURE #2: Per-Plate Settings (Major Feature)

## Child Tests - Playful Exploration

### Test 2.1: "The Switcharoo Game"
**Scenario:** See how fast you can change printer presets without breaking anything
```
Actions:
1. Load a multi-plate project
2. Rapidly switch plate presets: Bambu X1C → Prusa MK3 → Ender 3 → Voron 2.4
3. Switch back and forth 10 times quickly
4. Save project after each switch
5. Check if settings "stick" or get confused

Expected Fun:
- Does the UI flicker?
- Do any warnings pop up?
- Can you "break" the settings by going too fast?
- What happens to incompatible settings?

Bugs to Watch For:
- UI not updating
- Settings from previous preset leaking through
- Crashes from rapid changes
```

### Test 2.2: "The Impossible Plate"
**Scenario:** Try to create settings that make no physical sense
```
Actions:
1. Set printer to Bambu X1C (250mm x 250mm bed)
2. Set layer height to 0.001mm (ridiculously thin)
3. Set speed to 1000mm/s (ludicrously fast)
4. Set temperature to 500°C (way too hot for PLA)
5. Try to slice

Expected Fun:
- Does it let you?
- What warnings appear?
- Does it crash or gracefully handle it?
- Can you slice "impossible" settings?

Learning Goal:
- Test validation boundaries
- See what the software will and won't allow
```

### Test 2.3: "The Memory Palace"
**Scenario:** Save and load projects with increasingly complex plate configurations
```
Actions:
1. Create project with 1 plate, 1 object
2. Save as "simple.3mf"
3. Add 3 more plates, different printer for each
4. Save as "medium.3mf"
5. Add 10 plates total, all different printers and filaments
6. Save as "complex.3mf"
7. Close OrcaSlicer completely
8. Reopen and load each file in reverse order
9. Check if EVERYTHING is exactly as saved

Expected Fun:
- Does loading take longer for complex files?
- Are all settings preserved?
- Can you "break" the save format?
- What's the maximum number of plates before it struggles?

Measurement:
- File sizes: simple.3mf vs complex.3mf
- Load times: 1 plate vs 10 plates
- Memory usage during load
```

### Test 2.4: "The Copy-Paste Chaos"
**Scenario:** Clone plates and see if settings clone correctly
```
Actions:
1. Create plate with unique settings (specific printer, filaments, temps)
2. Duplicate/copy the plate
3. Check if duplicate has IDENTICAL settings
4. Modify original plate settings
5. Check if duplicate changed (it shouldn't!)
6. Delete original
7. Check if duplicate still works

Expected Fun:
- Are the clones truly independent?
- Can you create a "linked" clone by accident?
- What happens if you delete the template?
```

## Developer Tests - Professional Rigor

### Test 2.5: Edge Case - Empty Filament List
**Scenario:** What happens with zero filaments configured?
```
Test Case: TC-PP-001
Preconditions:
- Fresh OrcaSlicer install OR
- Manually clear all filament presets

Steps:
1. Create new plate
2. Open plate settings dialog
3. Attempt to assign filament presets
4. Expected: Graceful error or empty list
5. Actual: [DOCUMENT RESULT]

Validation:
- No null pointer dereferences
- UI doesn't freeze
- Error message is helpful (not cryptic)
- Can recover without restart

Pass Criteria:
✓ Application does not crash
✓ Error message displayed (if appropriate)
✓ User can close dialog and continue
✓ Can add filaments and retry
```

### Test 2.6: Edge Case - Maximum Filaments
**Scenario:** Stress test with maximum possible filaments
```
Test Case: TC-PP-002
Setup:
- Create 20 custom filament presets
- Name them Filament_01 through Filament_20

Steps:
1. Select all 20 filaments for single plate
2. Check UI layout (does it overflow?)
3. Save and load project
4. Slice a simple cube
5. Check G-code for all 20 filament references

Validation:
- UI displays all filaments (with scrollbar?)
- Filament order preserved on save/load
- G-code generation handles all 20
- No buffer overflows or array bounds errors

Performance Metrics:
- Time to open dialog: < 1 second
- Time to save project: < 5 seconds
- Memory usage: should be reasonable
```

### Test 2.7: Data Integrity - Preset Validation
**Scenario:** Test validation when presets go missing
```
Test Case: TC-PP-003
Setup:
1. Create project with custom printer preset "MyPrinter"
2. Assign "MyPrinter" to Plate 1
3. Save project as "test_missing.3mf"
4. Close OrcaSlicer
5. Delete "MyPrinter" preset from filesystem
6. Reopen OrcaSlicer
7. Load "test_missing.3mf"

Expected Behavior:
- Warning message: "Preset 'MyPrinter' not found"
- Options: Use default, Skip, Cancel
- If "Use default": Uses system default printer
- If "Skip": Plate marked with warning icon
- Project still loads (doesn't corrupt)

Validation:
✓ validate_custom_presets() called on load
✓ Warning message displayed
✓ User can choose action
✓ No crash or data loss
✓ Can save project after recovery
```

### Test 2.8: Concurrency - Rapid Multi-Plate Changes
**Scenario:** Change multiple plates simultaneously (if possible in UI)
```
Test Case: TC-PP-004
Steps:
1. Create 5 plates
2. Open plate settings for Plate 1
3. While dialog open, try to open plate settings for Plate 2
4. Expected: Either blocks or queues request
5. Change Plate 1 settings rapidly
6. Switch to Plate 2 before Apply/OK
7. Check for race conditions

Validation:
- Settings changes are atomic
- No data corruption between plates
- UI state consistent
- No memory leaks from abandoned dialogs
```

---

# FEATURE #5: Hierarchical Grouping (Major Feature)

## Child Tests - Playful Exploration

### Test 5.1: "The Nesting Doll Challenge"
**Scenario:** How deep can you nest groups?
```
Actions:
1. Create Volume A
2. Group it → "Group 1"
3. Create Volume B, add to Group 1
4. Create "Group 2" containing Group 1
5. Create "Group 3" containing Group 2
6. Keep nesting: Group 4 → Group 5 → Group 6...
7. See how deep you can go before:
   - UI breaks
   - Performance degrades
   - You lose track (get confused)

Expected Fun:
- Can you nest 10 levels deep? 20? 100?
- Does the hierarchy tree still display correctly?
- Can you still expand/collapse at level 10?
- What's the performance like with extreme nesting?

Measurement:
- Maximum nesting depth before UI issues
- Memory usage per nesting level
- Expand/collapse response time at depth 10+
```

### Test 5.2: "The Rename Rampage"
**Scenario:** Rename everything constantly and see if it tracks correctly
```
Actions:
1. Create 5 groups: A, B, C, D, E
2. Rename A → "Alpha"
3. Add volumes to Alpha
4. Rename Alpha → "Omega"
5. Save project
6. Rename Omega → "Group_Final"
7. Load project
8. Check: Is it saved as "Omega" or "Group_Final"?
9. Rename 10 more times
10. Check references in code

Expected Fun:
- Do old names linger in memory?
- Does save capture the CURRENT name?
- Can you create duplicate names?
- What if you rename to empty string ""?

Edge Cases to Try:
- Names with special chars: "Group<>&*"
- Very long names: "This_Is_A_Really_Long_Group_Name_With_Way_Too_Many_Characters_1234567890"
- Unicode: "组合" (Chinese), "グループ" (Japanese), "🎨" (emoji)
- Whitespace: "   " (all spaces)
```

### Test 5.3: "The Drag-and-Drop Dance"
**Scenario:** Move volumes between groups rapidly
```
Actions:
1. Create 3 groups: Red, Green, Blue
2. Create 9 volumes: V1-V9
3. Put V1-V3 in Red, V4-V6 in Green, V7-V9 in Blue
4. Now rapidly reorganize:
   - Drag V1 from Red to Blue
   - Drag V5 from Green to Red
   - Drag V9 from Blue to Green
5. Do this 20 times in random patterns
6. Save and reload
7. Check if volumes are in expected groups

Expected Fun:
- Does drag-and-drop animation glitch?
- Can you "lose" a volume mid-drag?
- What if you drop outside all groups?
- Can you drag a group into itself (circular reference)?

Chaos Mode:
- Use undo/redo during drag operations
- Drag while another dialog is open
- Drag multiple selected items simultaneously
```

### Test 5.4: "The Ungroup Apocalypse"
**Scenario:** Ungroup everything and see what survives
```
Actions:
1. Create complex hierarchy:
   - MainGroup
     - SubGroup1
       - Volume A
       - Volume B
     - SubGroup2
       - Volume C
       - SubGroup3
         - Volume D
2. Ungroup SubGroup3
   - Expected: Volume D moves up to SubGroup2
3. Ungroup SubGroup2
   - Expected: Volume C and D move up to MainGroup
4. Ungroup SubGroup1
   - Expected: Volume A and B move up to MainGroup
5. Ungroup MainGroup
   - Expected: All volumes loose, no groups remain

Check At Each Step:
- Are volume positions preserved?
- Are transformations (rotate, scale) preserved?
- Is print order correct after ungroup?
- Can you undo each ungroup step?

Expected Fun:
- Can you create "orphaned" volumes?
- What if you ungroup during slicing?
- Does Ctrl+Z correctly restore hierarchy?
```

## Developer Tests - Professional Rigor

### Test 5.5: Memory Management - Group Lifecycle
**Scenario:** Verify no memory leaks with create/delete cycles
```
Test Case: TC-HG-001
Tools: Windows Performance Monitor OR valgrind (Linux)

Steps:
1. Record baseline memory: Task Manager → Memory
2. Create 100 groups with 10 volumes each
3. Record memory after creation
4. Delete all groups
5. Record memory after deletion
6. Expected: Memory returns close to baseline

Repeat 10 Times:
- Memory should not grow significantly
- Check for "stair-stepping" memory (sign of leaks)

Validation:
- Memory growth < 50MB after 10 cycles
- Objects properly destroyed (check destructor calls)
- No dangling pointers in parent_object
- Volume references cleaned up
```

### Test 5.6: Data Structure Integrity - Circular References
**Scenario:** Attempt to create invalid group structures
```
Test Case: TC-HG-002
Objective: Ensure circular references are prevented

Attempt 1: Direct Circular Reference
1. Create Group A
2. Create Group B as child of A
3. Try to make A a child of B
4. Expected: Blocked with error message

Attempt 2: Indirect Circular Reference
1. Create Group A
2. Create Group B as child of A
3. Create Group C as child of B
4. Try to make A a child of C (creates A → B → C → A loop)
5. Expected: Blocked with error message

Validation:
- validate_group_hierarchy() called before insert
- Error message: "Circular reference detected"
- Original hierarchy unchanged
- No data corruption
```

### Test 5.7: Save/Load Format - 3MF Extension
**Scenario:** Verify group metadata saved correctly in 3MF
```
Test Case: TC-HG-003
Setup:
1. Create project with groups:
   - MainGroup (id=1, name="Root")
     - SubGroup (id=2, name="Branch")
       - Volume1 (assigned to SubGroup)

Steps:
1. Save as "group_test.3mf"
2. Extract 3MF (it's a ZIP file)
3. Open [Content_Types].xml
4. Check for group metadata extension
5. Open *.model file (XML)
6. Verify group structure present:

Expected XML Structure:
```xml
<model>
  <resources>
    <object id="1" type="model">
      <mesh>...</mesh>
      <metadata type="group">
        <group id="1" name="Root">
          <child id="2"/>
        </group>
        <group id="2" name="Branch" parent="1">
          <volume id="101"/>
        </group>
      </metadata>
    </object>
  </resources>
</model>
```

Validation:
✓ Group IDs unique and sequential
✓ Parent-child relationships encoded
✓ Volume assignments present
✓ Group names stored (including unicode)
✓ Can load in different OrcaSlicer instance
✓ Hierarchy perfectly reconstructed
```

### Test 5.8: Edge Case - Empty Group Behavior
**Scenario:** Groups with no volumes
```
Test Case: TC-HG-004
Steps:
1. Create group "EmptyGroup"
2. Don't add any volumes
3. Save project
4. Load project
5. Check EmptyGroup exists

Questions:
- Is empty group preserved on save?
- Can you add volumes to it later?
- Does it appear in object list?
- Can you nest other groups in it?

Validation:
- Empty groups either:
  Option A: Saved and restored exactly
  Option B: Omitted on save (cleaned up)
- Behavior is documented and intentional
- No crashes or undefined behavior
```

### Test 5.9: UI State - Expand/Collapse Persistence
**Scenario:** Check if UI state persists across sessions
```
Test Case: TC-HG-005
Steps:
1. Create nested group structure (3 levels)
2. Expand all groups in UI
3. Collapse MainGroup
4. Save project
5. Close OrcaSlicer
6. Reopen and load project
7. Check: Is MainGroup collapsed or expanded?

Expected Behavior:
- UI state (expand/collapse) should NOT be saved in 3MF
- All groups default to collapsed on load
- User can expand as needed
- OR: Application has separate UI state file

Validation:
- Consistent behavior across restarts
- No stale UI state from previous sessions
```

---

# FEATURE #6: Cutting Plane Adjustability (Minor Feature)

## Child Tests - Playful Exploration

### Test 6.1: "The Shrink Ray"
**Scenario:** Make the cutting plane ridiculously small
```
Actions:
1. Load a large model (like a dragon or benchy)
2. Activate cutting gizmo
3. Set plane width to 1mm
4. Set plane height to 1mm
5. Try to position the tiny plane to cut the model

Expected Fun:
- Can you even see the plane at 1mm x 1mm?
- Does it still cut properly?
- Is the selection hitbox reasonable?
- Can you "lose" the plane in the model?

Extreme Test:
- Width: 0.1mm (nearly invisible)
- Height: 0.1mm
- Try to interact with it
```

### Test 6.2: "The Giant Guillotine"
**Scenario:** Make the cutting plane absurdly large
```
Actions:
1. Load a small model (10mm cube)
2. Activate cutting gizmo
3. Set plane width to 10,000mm (10 meters!)
4. Set plane height to 10,000mm
5. Observe the scene

Expected Fun:
- Does the giant plane fill the entire viewport?
- Can you still see your tiny model?
- Does rendering slow down?
- Can you zoom out far enough to see the whole plane?
- What happens to camera controls?

Performance:
- Frame rate with giant plane
- Memory usage
- OpenGL draw call count
```

### Test 6.3: "The Aspect Ratio Madness"
**Scenario:** Create bizarre aspect ratios
```
Actions:
1. Set width to 1000mm
2. Set height to 1mm
3. Result: Super wide, super thin plane (like a paper strip)
4. Then reverse: width 1mm, height 1000mm (tall and narrow)
5. Try to cut model with these weird planes

Expected Fun:
- Does the visual representation stretch correctly?
- Can you accurately position a 1000:1 aspect ratio plane?
- Does the cut result look correct?
- UI/UX: Is this usable or confusing?
```

### Test 6.4: "The Auto-Size Toggle Dance"
**Scenario:** Rapidly toggle auto-size on and off
```
Actions:
1. Enable auto-size plane
2. Note the automatic dimensions
3. Disable auto-size
4. Manually change width/height
5. Re-enable auto-size
6. Check: Does it recalculate or keep manual values?
7. Repeat 20 times rapidly

Expected Fun:
- Does the plane "jump" when auto-size activates?
- Can you create a "flicker" effect?
- What's the auto-size algorithm?
- Does it consider model bounding box?
```

## Developer Tests - Professional Rigor

### Test 6.5: Boundary Validation - Dimension Limits
**Scenario:** Test min/max validation for plane dimensions
```
Test Case: TC-CP-001
Test Negative Values:
- Width: -100mm (should reject or convert to absolute value)
- Height: -50mm

Test Zero:
- Width: 0mm (should reject, can't cut with zero-width plane)
- Height: 0mm

Test Floating Point:
- Width: 0.001mm (very small but valid)
- Height: 123.456789mm (high precision)

Test Maximum:
- Width: 9999999mm (essentially infinite)
- Height: 9999999mm
- Check: Memory allocation, rendering

Validation:
✓ Input validation prevents invalid values
✓ Error messages are clear
✓ Default values are sensible
✓ No crashes from extreme values
```

### Test 6.6: State Management - Auto-Size Logic
**Scenario:** Verify auto-size calculates correctly
```
Test Case: TC-CP-002
Setup:
1. Load cube 20mm x 20mm x 20mm
2. Enable m_auto_size_plane = true
3. Activate cutting gizmo

Expected Auto-Size:
- Should calculate plane to fit model
- Algorithm: Possibly 1.5x model bounding box?
- Or: Match largest dimension?

Test Cases:
Model        | Expected Plane Size
20x20x20mm   | ?? x ?? (DOCUMENT)
100x10x10mm  | ?? x ?? (DOCUMENT)
10x100x10mm  | ?? x ?? (DOCUMENT)

Then:
1. Disable auto-size
2. Manually set 50mm x 50mm
3. Re-enable auto-size
4. Check: Does it recalculate or keep 50x50?

Validation:
- Auto-size algorithm documented
- Consistent across different model sizes
- Respects user manual override (or doesn't, by design)
```

### Test 6.7: Rendering - Transparency and Depth
**Scenario:** Verify visual representation is correct
```
Test Case: TC-CP-003
Visual Checks:
1. Plane should be semi-transparent
2. Can see model through plane
3. Plane highlights on hover
4. Plane color indicates active/inactive state

OpenGL Validation:
- Check alpha blending enabled
- Depth buffer handling correct
- Z-fighting avoided (plane + model)
- Selection hitbox matches visual

Test Overlapping Geometry:
1. Position plane inside model
2. Rotate plane 45 degrees
3. Check rendering quality
4. No visual artifacts or flickering
```

### Test 6.8: Precision - Cut Result Accuracy
**Scenario:** Verify cut position matches plane position exactly
```
Test Case: TC-CP-004
Setup:
1. Load calibration cube (20mm x 20mm x 20mm)
2. Position plane at exact X=10mm (middle)
3. Execute cut
4. Measure resulting two pieces

Expected:
- Piece 1: 10mm x 20mm x 20mm
- Piece 2: 10mm x 20mm x 20mm

Validation:
1. Export both STL files
2. Open in external tool (Blender, MeshLab)
3. Measure actual dimensions
4. Tolerance: ±0.01mm

Test Different Angles:
- Cut at 0° (aligned with axis)
- Cut at 45° diagonal
- Cut at 30° arbitrary angle
- Verify accuracy for all angles
```

---

# FEATURE #3 & #4: Multi-Material Flush Control

## Child Tests - Playful Exploration

### Test 3.1: "The Rainbow Tower"
**Scenario:** Create prime tower with every filament enabled
```
Actions:
1. Set up 8-extruder printer (or maximum supported)
2. Enable all filaments for prime tower
3. Load a simple cube
4. Slice and preview
5. Check the prime tower in preview

Expected Fun:
- Does the prime tower look like a rainbow?
- How tall is it compared to the model?
- Can you see distinct color layers?
- What happens if you use 16 filaments?

Visual Goal:
- Prime tower should show all filaments used
- Each layer purges unused filaments
- Colors blend beautifully in preview
```

### Test 3.2: "The Zero Flush Challenge"
**Scenario:** Disable ALL flushing and see what happens
```
Actions:
1. Multi-material model (2+ colors)
2. Set prime tower filaments: [] (empty list)
3. Set support flush filaments: [] (empty)
4. Set infill flush filaments: [] (empty)
5. Slice and preview

Expected Fun:
- Does it still slice?
- Warnings about no purge area?
- G-code has no purge commands?
- What does the print look like (simulate)?

Hypothesis:
- Colors will bleed into each other
- First layers will be contaminated
- Might see "gradient" effects unintentionally
```

### Test 3.3: "The Selective Purge Game"
**Scenario:** Only purge specific filaments, not others
```
Actions:
1. Use 4 filaments: Red, Blue, Green, Yellow
2. Set prime tower filaments: [Red, Blue] (only these)
3. Model uses all 4 colors
4. Slice and check G-code

Expected Behavior:
- Red and Blue purge to prime tower
- Green and Yellow purge... where?
- Check G-code for T2 (Green) and T3 (Yellow) purge locations

Questions:
- Do non-tower filaments purge to support?
- Or infill?
- Or do they skip purging (color bleed)?
- Is this a valid configuration?
```

## Developer Tests - Professional Rigor

### Test 3.4: Validation - Integer List Parsing
**Scenario:** Test coInts parsing for filament lists
```
Test Case: TC-MF-001
Configuration: wipe_tower_filaments

Test Valid Inputs:
- "0,1,2,3" → [0,1,2,3]
- "0" → [0] (single element)
- "1,0,3,2" → [1,0,3,2] (order preserved)
- "" (empty string) → [] (empty list)

Test Invalid Inputs:
- "0,1,abc,3" → Error or [0,1,3]? (skip invalid)
- "0 1 2" (spaces, not commas) → Error
- "-1,0,1" (negative index) → Error
- "999" (out of range extruder) → Error or skip?

Test Duplicates:
- "0,1,1,2" → [0,1,1,2] or [0,1,2]? (deduplicate?)

Validation:
✓ Parse function handles all formats
✓ Invalid input triggers warning
✓ Empty list is valid (means no flushing)
✓ Duplicate handling documented
```

### Test 3.5: G-code Generation - Purge Commands
**Scenario:** Verify correct G-code for different flush configs
```
Test Case: TC-MF-002
Setup:
- 2-color model: Red (T0), Blue (T1)
- Layer 1: Red only
- Layer 2: Blue only
- Prime tower enabled

Configuration A: Tower only
- wipe_tower_filaments: [0,1]
- support_flush_filaments: []
- infill_flush_filaments: []

Expected G-code Pattern:
```
; Layer 2 - Tool change T0 → T1
T1                     ; Switch to Blue
G1 X100 Y100 Z...      ; Move to prime tower
G1 E... F...           ; Extrude purge volume
; Now print model with T1
```

Configuration B: Support flush
- wipe_tower_filaments: []
- support_flush_filaments: [0,1]
- infill_flush_filaments: []

Expected:
- No prime tower G-code
- Purge happens in support regions
- G-code: Move to support, extrude, then model

Configuration C: Infill flush
- wipe_tower_filaments: []
- support_flush_filaments: []
- infill_flush_filaments: [0,1]

Expected:
- No prime tower
- Purge in infill regions first
- Less waste than prime tower
```

### Test 3.6: Volume Calculation - Purge Amount
**Scenario:** Verify purge volume is calculated correctly
```
Test Case: TC-MF-003
Background:
- Different filaments need different purge volumes
- PLA → PLA: Small purge (similar materials)
- PLA → PETG: Large purge (different melting temps)
- White → Black: Large purge (color contamination)

Test Matrix:
From      | To      | Expected Purge Volume
----------|---------|----------------------
PLA White | PLA Red | ~50mm³
PLA White | PLA Black | ~150mm³ (opaque)
PLA       | PETG    | ~200mm³ (temp diff)
PETG      | PLA     | ~250mm³ (reverse temp)

Validation Steps:
1. Parse G-code for tool change
2. Calculate extrusion volume E commands
3. Compare to expected purge volume
4. Tolerance: ±20mm³

Formula Check:
- Purge volume = π × r² × length
- Where r = nozzle radius (0.2mm for 0.4mm nozzle)
- Length calculated from E values in G-code
```

### Test 3.7: Edge Case - Single Filament
**Scenario:** Multi-material features with only 1 filament
```
Test Case: TC-MF-004
Setup:
- Model: Single color (doesn't need multi-material)
- Configuration: All flush options enabled
- wipe_tower_filaments: [0]
- support_flush_filaments: [0]
- infill_flush_filaments: [0]

Expected Behavior:
- No prime tower generated (not needed)
- No purge commands (no tool changes)
- G-code should be identical to single-material slice
- Warning: "Multi-material flush settings ignored (single extruder)"

Validation:
✓ Slice completes without errors
✓ No prime tower in output
✓ G-code has no T1, T2... commands
✓ Performance: Not slower than non-MM slice
```

---

# INTEGRATION TESTS - Cross-Feature

## Test I-1: Per-Plate Settings + Hierarchical Groups
**Scenario:** Different plates with grouped objects
```
Setup:
1. Plate 1: Printer A, Filament Red
   - Group "Characters"
     - Volume: Dragon
     - Volume: Knight
2. Plate 2: Printer B, Filament Blue
   - Group "Terrain"
     - Volume: Castle
     - Volume: Trees

Test Actions:
1. Save project as "multi_plate_groups.3mf"
2. Load project
3. Verify:
   - Plate 1 has Printer A and Red filament
   - Plate 2 has Printer B and Blue filament
   - Group "Characters" only on Plate 1
   - Group "Terrain" only on Plate 2
4. Move Dragon from Plate 1 to Plate 2
5. Check: Dragon now uses Printer B settings?
6. Check: Is Dragon still in "Characters" group?

Expected Behavior:
- Plate settings override object settings
- Groups are plate-specific OR global (document which)
- Moving object between plates updates its settings
```

## Test I-2: Cutting Plane + Groups
**Scenario:** Cut a grouped object
```
Setup:
1. Create Group "Toy"
   - Volume: Head
   - Volume: Body
   - Volume: Legs
2. Activate cutting gizmo on "Body"
3. Position plane to cut Body in half
4. Execute cut

Questions:
- Does cutting one volume affect group?
- Are cut pieces automatically added to group?
- Can you cut the entire group at once?
- What happens to group hierarchy after cut?

Test Variations:
A. Cut single volume in group
B. Cut nested group (all volumes inside)
C. Cut and then ungroup
D. Undo cut - does group restore?
```

## Test I-3: Multi-Material + Per-Plate
**Scenario:** Different filament flush settings per plate
```
Setup:
1. Plate 1:
   - Printer: Bambu X1C (4 extruders)
   - Filaments: Red, Blue, Green, Yellow
   - Prime tower: [0,1,2,3] (all)
2. Plate 2:
   - Printer: Prusa XL (5 extruders)
   - Filaments: Black, White, Gray, Orange, Purple
   - Prime tower: [0,1] (only first two)

Test:
1. Slice both plates
2. Check G-code for Plate 1: 4-color prime tower
3. Check G-code for Plate 2: 2-color prime tower, others flush to infill?
4. Verify correct behavior per plate

Validation:
- Per-plate settings don't interfere with each other
- G-code clearly separated per plate
- Print time estimates accurate for each plate
```

---

# STRESS TESTS - Performance & Limits

## Stress Test 1: Massive Project
**Scenario:** Maximum complexity project
```
Configuration:
- 10 plates
- Each plate: 100 objects
- 50 hierarchical groups (nested 5 levels deep)
- All objects multi-material (4 colors)
- Each plate has different printer preset

Metrics to Measure:
- Project load time: ___ seconds
- Project save time: ___ seconds
- File size: ___ MB
- Memory usage: ___ MB
- Slice time: ___ minutes
- UI responsiveness: Lag? Freeze?

Goals:
- Load time < 30 seconds
- Save time < 60 seconds
- File size < 500MB
- Memory usage < 4GB
- No crashes
- Can navigate UI smoothly
```

## Stress Test 2: Rapid Operations
**Scenario:** Perform operations as fast as possible
```
Actions (In 60 seconds):
1. Create 50 groups
2. Rename each group
3. Add 10 volumes to each group
4. Move volumes between groups randomly
5. Collapse/expand all groups 10 times
6. Save project 5 times
7. Undo 20 operations
8. Redo 20 operations

Measurement:
- Operations completed in 60 seconds: ___
- CPU usage during test: ___% average
- Memory usage: Start ___ MB → End ___ MB (leak check)
- UI lag/freeze: Yes/No
- Crashes: Yes/No

Pass Criteria:
✓ Complete at least 80% of operations
✓ No crashes
✓ Memory growth < 200MB
✓ UI remains responsive (no freeze > 2 seconds)
```

## Stress Test 3: Extreme Undo/Redo
**Scenario:** Test undo/redo stack limits
```
Actions:
1. Perform 1,000 unique operations:
   - Create group
   - Rename group
   - Add volume
   - Move volume
   - Delete volume
   - (repeat)
2. Undo all 1,000 operations
3. Redo all 1,000 operations
4. Undo 500
5. Perform 50 new operations (breaks redo chain)
6. Undo those 50
7. Verify project state is consistent

Validation:
- Undo stack doesn't overflow
- Memory usage reasonable (not storing 1,000 full state copies)
- Redo chain correctly invalidated when new ops performed
- Final state matches expected state
- No corrupted data
```

---

# REAL-WORLD SCENARIOS - User Stories

## Scenario 1: "The Multi-Printer Workshop"
**User:** Maker with 3 printers (Bambu X1C, Prusa MK4, Ender 3)
```
Story:
"I have a big order: 50 dragon miniatures. I want to distribute the print
across my 3 printers to finish faster. Each printer has different profiles."

Test:
1. Load dragon.stl
2. Arrange copies: 20 on Plate 1, 20 on Plate 2, 10 on Plate 3
3. Plate 1: Bambu X1C, PLA Red
4. Plate 2: Prusa MK4, PETG Blue
5. Plate 3: Ender 3, PLA Green
6. Slice all plates
7. Export G-code for each plate separately

Validation:
- Each G-code file uses correct printer settings
- Print times accurate per printer
- Can load G-code files on respective printers
- No cross-contamination of settings
```

## Scenario 2: "The Complex Assembly"
**User:** Designer creating multi-part toy
```
Story:
"I'm designing a robot toy with 20 parts. I want to organize them into
groups: Head, Body, Arms, Legs. Some parts need supports, others don't."

Test:
1. Import 20 STL files
2. Create groups:
   - Head: Helmet, Visor, Antennae
   - Body: Chest, Back
   - Arms: Left Upper, Left Lower, Right Upper, Right Lower
   - Legs: Left Thigh, Left Shin, Right Thigh, Right Shin
3. Set support settings per group
4. Arrange on plate for efficient printing
5. Slice and check supports

Validation:
- Groups help organize complex project
- Support settings applied correctly per group
- Print order logical (related parts together)
- Easy to export/share project with groups intact
```

## Scenario 3: "The Color Gradient Vase"
**User:** Artist creating multi-color prints
```
Story:
"I want to print a vase that transitions from white at bottom to black
at top, with 3 intermediate gray shades. I want minimal waste."

Test:
1. Model: Vase, 150mm tall
2. Filaments: White, Light Gray, Medium Gray, Dark Gray, Black (5 colors)
3. Configure layer-by-layer filament changes
4. Enable infill flush for all filaments (to minimize prime tower)
5. Slice and check:
   - Prime tower volume
   - Infill flush usage
   - Total filament waste

Validation:
- Infill flush reduces waste vs. prime tower only
- Color transitions are smooth (no contamination)
- Print time reasonable
- Supports selective flushing configuration
```

---

# REGRESSION TESTS - After Bug Fixes

## Regression 1: Plate Settings Save/Load
**Background:** If there was a bug where plate settings weren't saved correctly
```
Test:
1. Create project with 3 plates, different settings each
2. Save project
3. Close OrcaSlicer
4. Reopen project
5. Verify ALL plate settings are correct:
   - Printer preset names
   - Filament preset names
   - Custom parameters (temps, speeds)

Automated Check:
- Write script to parse .3mf file
- Extract plate configuration XML
- Compare to expected values
- Run test as part of CI/CD
```

## Regression 2: Group Memory Leak
**Background:** If there was a bug causing memory leaks in group operations
```
Test:
1. Start OrcaSlicer, note memory usage
2. Create 100 groups
3. Delete all 100 groups
4. Check memory usage (should return to baseline)
5. Repeat 10 times
6. Memory should not grow significantly

Automated Check:
- Use memory profiler (Windows: PerfView, Linux: Valgrind)
- Run test script
- Assert memory growth < 100MB after 10 cycles
- Flag as failure if memory leak detected
```

## Regression 3: Cutting Plane Crash
**Background:** If there was a bug causing crash with specific plane dimensions
```
Test:
1. Load model
2. Activate cutting gizmo
3. Set plane dimensions to previously-crash-causing values
4. Execute cut
5. Verify no crash

Automated Check:
- Run in debug mode with crash handler
- If crash occurs, capture stack trace
- Log crash details for analysis
- Test should complete without crash
```

---

# ACCEPTANCE CRITERIA - Release Checklist

## Feature #2: Per-Plate Settings
- [ ] Can create plate with custom printer preset
- [ ] Can assign multiple filament presets
- [ ] Settings save correctly in .3mf file
- [ ] Settings load correctly from .3mf file
- [ ] Warning shown for missing presets
- [ ] No crashes when switching presets rapidly
- [ ] Performance acceptable (< 1 second to open dialog)
- [ ] All UI elements display correctly
- [ ] Tooltips are helpful and accurate
- [ ] Documented in user manual

## Feature #5: Hierarchical Grouping
- [ ] Can create groups via UI
- [ ] Can rename groups (including special characters)
- [ ] Can nest groups (at least 5 levels deep)
- [ ] Can expand/collapse groups in UI
- [ ] Can drag volumes between groups
- [ ] Can ungroup at any level
- [ ] Groups save/load correctly in .3mf
- [ ] No memory leaks with group operations
- [ ] Undo/redo works for all group operations
- [ ] Documented in user manual

## Feature #6: Cutting Plane Adjustability
- [ ] Plane width is adjustable
- [ ] Plane height is adjustable
- [ ] Auto-size plane option works
- [ ] Plane renders correctly in 3D view
- [ ] Plane dimensions validate (min/max)
- [ ] Cut result is accurate to plane position
- [ ] Settings persist in session
- [ ] Performance acceptable (60 FPS with plane active)
- [ ] Documented in user manual

## Features #3 & #4: Multi-Material Flush
- [ ] Prime tower filament list configurable
- [ ] Support flush filament list configurable
- [ ] Infill flush filament list configurable
- [ ] Lists parse correctly (coInts format)
- [ ] G-code generated correctly for each config
- [ ] Purge volumes calculated correctly
- [ ] Works with per-plate settings
- [ ] No errors with single-filament projects
- [ ] Documented in user manual

## Integration
- [ ] All features work together without conflicts
- [ ] No crashes in any test scenario
- [ ] Performance acceptable (project load < 30s)
- [ ] Memory usage reasonable (< 4GB for large projects)
- [ ] File format backward compatible
- [ ] Regression tests all pass
- [ ] Code review completed
- [ ] Unit tests written (if applicable)
- [ ] Manual testing completed by 2+ testers
- [ ] User documentation updated

---

# EXPLORATORY TESTING - "What If..." Questions

## The Child's Perspective

1. "What if I hold down the button really long?"
   - Try holding Rename for 10 seconds
   - Try holding Create Group for 30 seconds
   - Does anything break? Unexpected behavior?

2. "What if I click everything really fast?"
   - Rapid clicking on UI elements
   - Can you create a "race condition" in the UI?
   - Does double-click do something different?

3. "What if I type weird stuff in the text boxes?"
   - Group name: SQL injection attempt ' OR 1=1--
   - Group name: HTML tags <script>alert(1)</script>
   - Group name: Path traversal ../../etc/passwd
   - Does input sanitization work?

4. "What if I make it really big and really small?"
   - Cutting plane: 0.001mm x 100000mm
   - 10,000 groups in one project
   - Group name: 10,000 characters long

5. "What if I do things backward?"
   - Ungroup before grouping
   - Save before creating anything
   - Redo before doing anything
   - Load project before OrcaSlicer fully started

6. "What if I don't follow the instructions?"
   - Skip steps in documentation
   - Do operations out of order
   - Does software guide user back on track?

7. "What if I break it on purpose?"
   - Delete files while OrcaSlicer is open
   - Modify .3mf file manually (corrupt it)
   - Fill disk space during save operation
   - Disconnect network during cloud sync (if applicable)

## The Developer's Perspective

1. "What if the file system fails?"
   - Disk full during save
   - Permissions denied on config directory
   - File locked by another process

2. "What if the data is corrupted?"
   - Malformed XML in .3mf file
   - Missing required fields
   - Invalid data types (string where int expected)

3. "What if resources are constrained?"
   - Run on 4GB RAM system (low memory)
   - Run on old CPU (slow performance)
   - Run on integrated GPU (limited OpenGL)

4. "What if concurrent operations conflict?"
   - Two instances of OrcaSlicer open same file
   - Background auto-save during user operation
   - Slicer running while user modifies project

5. "What if the user environment is unusual?"
   - Non-English locale (Chinese, Japanese, Arabic)
   - Right-to-left UI layout (Arabic, Hebrew)
   - High DPI display (4K, 8K)
   - Multiple monitors with different DPI

6. "What if dependencies are missing?"
   - OpenGL drivers outdated
   - Required DLL missing (Windows)
   - Library version mismatch (Linux)

---

# TESTING TOOLS & AUTOMATION

## Manual Testing Tools

1. **Stopwatch/Timer**: Measure operation times
2. **Task Manager**: Monitor memory/CPU usage
3. **Notepad**: Keep log of issues found
4. **Screen Recording**: Capture bugs for reproduction
5. **Compare Tool**: Verify .3mf files before/after changes

## Automated Testing Tools

1. **Scripting**: Python scripts to generate test projects
2. **XML Parser**: Validate .3mf structure programmatically
3. **Memory Profiler**: Detect leaks (Valgrind, PerfView)
4. **CI/CD**: Run regression tests on every commit
5. **Fuzzer**: Generate random inputs to find crashes

## Test Data Sets

1. **Simple Models**: Cube, sphere, cylinder (fast tests)
2. **Complex Models**: Dragons, sculptures (stress tests)
3. **Edge Case Models**: Non-manifold, tiny features
4. **Real Projects**: User-submitted .3mf files

---

# DOCUMENTATION TO CREATE

After testing, document:

1. **Test Results Summary**
   - Total tests run: ___
   - Tests passed: ___
   - Tests failed: ___
   - Bugs found: ___
   - Bugs fixed: ___

2. **Known Issues**
   - List of bugs not yet fixed
   - Workarounds for users
   - Severity ratings

3. **User Guide Updates**
   - Screenshots of new features
   - Step-by-step tutorials
   - FAQ for common questions

4. **Developer Notes**
   - API documentation for new classes
   - Code comments for complex logic
   - Architecture decisions made

---

# CREATIVE TEST CHALLENGES - Gamification

## Challenge 1: "The Speed Run"
**Goal:** Complete all basic tests in under 30 minutes
- Create project with 3 plates
- Each plate has different settings
- Create 5 groups with 10 volumes
- Perform 20 group operations
- Slice all plates
- Save and reload project
- Time: ___ minutes (goal: < 30)

## Challenge 2: "The Bug Hunter"
**Goal:** Find 10 bugs in 1 hour
- Exploratory testing, no script
- Try to break things creatively
- Document each bug found
- Bugs found: ___ (goal: 10+)

## Challenge 3: "The Endurance Test"
**Goal:** Keep OrcaSlicer running for 24 hours
- Perform random operations every 5 minutes
- Script to automate if possible
- Monitor memory usage over time
- Check for memory leaks, crashes
- Result: Ran for ___ hours without crash

## Challenge 4: "The Compatibility Test"
**Goal:** Load project on 5 different computers
- Windows 10, Windows 11, Linux, macOS
- Different OrcaSlicer versions
- Verify project loads identically
- Document any platform-specific issues

## Challenge 5: "The User Simulation"
**Goal:** Act like a real user for 2 hours
- Don't follow test scripts
- Use software how you naturally would
- Try to complete a real project (design something!)
- Note any confusion, friction, or delight
- Write user experience report

---

**END OF CREATIVE TESTING PLAYBOOK**

This playbook combines:
- 🎨 Creative, exploratory testing (child perspective)
- 🔬 Systematic, rigorous testing (developer perspective)
- 🎯 Real-world scenarios
- 🔥 Stress testing
- 🏆 Gamification for motivation

**Next Steps:**
1. Choose tests based on priority
2. Execute tests systematically
3. Document results in TESTING-RESULTS.md
4. File bugs in issue tracker
5. Iterate until all acceptance criteria met

**Remember:**
- Testing is creative AND methodical
- Both approaches find different bugs
- Have fun while being thorough!
- Document everything for future reference
