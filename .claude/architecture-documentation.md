# OrcaSlicer Architecture Documentation

## Session Information
- Date: 2026-02-13
- Purpose: Comprehensive codebase analysis for multi-extruder feature implementation
- Status: In Progress

## Project Overview
OrcaSlicer is an open-source 3D slicer forked from Bambu Studio, built with C++, wxWidgets GUI, and CMake build system.

---

## Directory Structure Analysis

### Core Components

**libslic3r/** - Platform-independent slicing engine
- 273+ root-level source files
- Key subdirectories: GCode/, Fill/, Arachne/, SLA/, Support/, Format/, Geometry/
- Core classes: Print, PrintObject, PrintRegion, Layer, GCode, Extruder, Model
- Supports up to 64 extruders (MAXIMUM_EXTRUDER_NUMBER = 64)

**slic3r/** - Application framework and wxWidgets GUI
- GUI/ subdirectory: 300+ files organized into Widgets/, Gizmos/, Jobs/, DeviceCore/
- Main classes: GUI_App, MainFrame, Plater, GLCanvas3D, Tab, ObjectList
- Configuration management via Preset system

**libvgcode/** - G-code visualization library (45 files)

### GUI Architecture

**Main Window Hierarchy:**
```
OrcaSlicer.cpp → GUI_App → MainFrame
                              ├── Plater (central workspace)
                              │   ├── GLCanvas3D (3D view)
                              │   ├── Sidebar (presets & controls)
                              │   ├── ObjectList (tree view)
                              │   └── GLGizmosManager (manipulation tools)
                              └── Tab system (Print/Filament/Printer settings)
```

**Key GUI Systems:**
- **Plater**: Central 3D editing workspace with sidebar
- **GLCanvas3D**: OpenGL rendering with object picking and gizmo interaction
- **Gizmos**: Interactive tools (Move, Rotate, Scale, Cut, MMSegmentation, Assembly, etc.)
- **Tab/Page/ConfigOptionsGroup/Field**: Settings UI hierarchy
- **Selection**: Manages selected objects/volumes
- **ObjectList**: Tree view of objects with context menus

**Settings Flow:**
Config File → PresetBundle → Tab → Page → ConfigOptionsGroup → Field → Model Config → Background Slicing

### Multi-Material Systems

**Extruder Management:**
- Extruder class tracks state for up to 64 extruders
- Supports shared E-axis (SEMM) and per-extruder modes
- Per-filament retraction settings already exist in PrintConfig
- ToolOrdering optimizes extruder switches

**Prime Tower (Wipe Tower):**
- WipeTower/WipeTower2 classes generate purge tower
- Configurable position, width, rotation, cone angle, wall type
- FilamentParameters struct holds per-filament flush settings
- flush_volumes_matrix defines purge amounts between materials

**Flush System:**
- flush_into_objects, flush_into_infill, flush_into_support flags
- WipingExtrusions class marks extrusions for wiping
- Flush volume calculation in ToolOrdering

**AMS/MMU Support:**
- FilamentGroup algorithm groups filaments for AMS slots
- filament_map array maps logical filaments to physical extruders
- Strategies: BestCost, BestFit, KMedioids clustering

### Configuration Systems

**Hierarchy:**
```
FullPrintConfig
├── PrintConfig (printer/global settings)
├── PrintObjectConfig (per-object overrides)
└── PrintRegionConfig (per-region/volume overrides)
```

**Preset System:**
- PresetBundle manages all preset collections
- System presets (read-only) + User presets (editable)
- Profiles stored as .ini files
- Per-filament arrays for multi-material settings

---

## Feature Request Analysis (Reddit Post)

### 1. Multi Extruder Settings - Per-Filament Retraction Override

**User Request:**
Override printer-level retraction settings with filament-specific values when swapping heads. Example: TPU needs different retraction (less than 10mm default) to avoid damaging filament.

**Current State:**
✅ **Already exists in PrintConfig** - All per-filament retraction settings are implemented:
- `filament_retraction_length` (ConfigOptionFloats)
- `filament_retraction_speed` (ConfigOptionFloats)
- `filament_deretraction_speed` (ConfigOptionFloats)
- `filament_retract_restart_extra` (ConfigOptionFloats)
- `filament_retract_before_wipe` (ConfigOptionFloats)
- `filament_wipe_distance` (ConfigOptionFloats)
- `filament_long_retractions_when_cut` (ConfigOptionFloatsOrPercents)
- `filament_retraction_distances_when_cut` (ConfigOptionFloats)

**Issue:** Settings exist in backend but may not be exposed in GUI or users don't know about them.

**Required Changes:**
- ✅ Backend: NO CHANGES NEEDED - already implemented
- GUI: Verify these settings are visible in Filament settings tab
- Documentation: Make these settings more discoverable
- Consider: Add tooltip explaining override behavior

**Files Involved:**
- `src/libslic3r/PrintConfig.cpp` (lines 2537-2579) - Already defined
- `src/slic3r/GUI/Tab.cpp` - Filament tab UI (verify visibility)

---

### 2. Multi-Per-Plate Settings (Filament & Printer Profiles)

**User Request:**
Allow different filament profiles and printer selection per plate within the same project. Use case: Large multi-plate projects where some plates fit K3M, others fit U1. Avoid having 5 OrcaSlicer instances open.

**Current State:**
❌ **Not supported** - Currently:
- One printer per project session
- One set of filament profiles per project
- Plate system exists but shares global printer/filament config

**Technical Considerations:**
- Print class has `m_plate_index` and plate-specific settings like `wipe_tower_x/y`
- Would need per-plate:
  - `printer_settings_id` (reference to printer profile)
  - `filament_settings_ids[]` (array of filament profile IDs)
- Complex interaction with background slicing (would need to slice per-plate)
- Need UI to switch between plate configs

**Required Changes:**
1. **Backend:**
   - Extend `PlateData` structure to store printer/filament profile references
   - Modify `Print::apply_config()` to support per-plate configs
   - Update 3MF format to serialize per-plate settings

2. **GUI:**
   - Add per-plate settings panel in Plater
   - Comboboxes to select printer/filament per plate
   - Visual indicator showing which plate has which config
   - Validation: ensure models fit printer bed size

3. **Slicing:**
   - BackgroundSlicingProcess needs to slice each plate with its config
   - Handle cross-plate dependencies (none expected)

**Files Involved:**
- `src/libslic3r/Print.hpp` - Add per-plate config storage
- `src/libslic3r/PartPlate.hpp/cpp` - Extend PlateData structure
- `src/libslic3r/Format/bbs_3mf.cpp` - Serialize per-plate settings
- `src/slic3r/GUI/Plater.hpp/cpp` - Add per-plate UI
- `src/slic3r/GUI/PartPlateList.hpp/cpp` - Plate list with config indicator
- `src/slic3r/GUI/BackgroundSlicingProcess.cpp` - Multi-config slicing

---

### 3. Prime Tower - Material-Specific Assignment

**User Request:**
Allow choosing which specific materials/colors go into the prime tower. Problem: Incompatible materials (PLA + TPU) cause tower to fall apart. Want to dedicate primitives as flush objects for specific filaments only.

**Current State:**
⚠️ **Partially exists:**
- `wipe_tower_filament` setting exists but undocumented/unclear behavior
- `flush_into_objects` exists for object flushing
- Cannot specify per-object which materials to flush into it
- Prime tower is "all or nothing" - all materials purge into same tower

**Desired Behavior:**
- Assign specific filament IDs to specific flush objects/tower sections
- Example: PLA tower (filaments 1,2,3) and TPU flush object (filament 4)
- Prevent incompatible material mixing in tower

**Required Changes:**
1. **Backend:**
   - Add `wipe_tower_filaments` (ConfigOptionInts) - array of filament IDs for tower
   - Add per-object `flush_filaments` (ConfigOptionInts) - which filaments flush into this object
   - Modify WipeTower generation to only purge specified filaments
   - Update WipingExtrusions to respect per-object filament restrictions

2. **GUI:**
   - In wipe tower settings: Multi-select checkboxes for filaments
   - Per-object setting: "Use as flush object for filaments: [checkboxes]"
   - Visual indicator on objects designated as flush targets

3. **Logic:**
   - ToolOrdering must respect filament constraints
   - If filament can't use tower, must use object or full purge

**Files Involved:**
- `src/libslic3r/PrintConfig.hpp/cpp` - Add new config options
- `src/libslic3r/GCode/WipeTower.cpp` - Filter filaments
- `src/libslic3r/GCode/ToolOrdering.cpp` - Respect flush constraints
- `src/slic3r/GUI/Tab.cpp` - Add UI for wipe tower filament selection
- `src/slic3r/GUI/GUI_ObjectSettings.cpp` - Per-object flush filament selection

---

### 4. Flushing into Supports - Material ID Selection

**User Request:**
Choose specific material IDs that can flush into supports. Similar to prime tower issue - avoid incompatible materials (PETG + PLA, PLA + TPU) mixing in supports causing failures. Use case: 3:1 ratio where 3 materials work together, 4th is incompatible.

**Current State:**
⚠️ **Basic feature exists:**
- `flush_into_support` (ConfigOptionBool) - global on/off
- `flush_into_infill` (ConfigOptionBool) - global on/off
- No per-filament control

**Desired Behavior:**
- `support_flush_filaments` array - which filaments can flush into support
- Example: Filaments 1,2,3 can flush into supports; filament 4 cannot
- Different from support material selection (which extruder prints support)

**Required Changes:**
1. **Backend:**
   - Add `support_flush_filaments` (ConfigOptionInts) - allowed filament IDs
   - Add `infill_flush_filaments` (ConfigOptionInts) - allowed for infill flushing
   - Modify WipingExtrusions::mark_wiping_extrusions() to check allowed filaments

2. **GUI:**
   - In Print settings → Flush options: Multi-select for support flush filaments
   - Checkboxes: "Flush into support for: [F1] [F2] [F3] [F4]"

3. **Logic:**
   - When marking support for wiping, check if current filament is in allowed list
   - Fall back to tower or object if support not allowed

**Files Involved:**
- `src/libslic3r/PrintConfig.hpp/cpp` - Add flush filament arrays
- `src/libslic3r/GCode/ToolOrdering.cpp` (lines 1569-1694) - Update mark_wiping_extrusions()
- `src/slic3r/GUI/Tab.cpp` - Add multi-select UI in Print settings

---

### 5. Groupings Within Objects (Hierarchical)

**User Request:**
Add hierarchical grouping capability. Current group system merges all parts into single color. Need: Group parts while maintaining individual colors, prevent re-splitting on ungroup, better organization for complex multi-part/multi-color objects.

**Current State:**
❌ **Limited grouping:**
- Objects can be grouped (forces single color)
- Parts within object (ModelVolume) can have individual extruders
- No intermediate grouping layer
- Cut/split operations reset grouping

**Desired Behavior:**
```
Object A (e.g., Robot Assembly)
├── Group: Body (red)
│   ├── Part: Torso
│   └── Part: Arms
├── Group: Head (blue)
│   ├── Part: Face
│   └── Part: Hat
└── Part: Base (green)
```

**Current Hierarchy:**
```
ModelObject
└── ModelVolume[] (parts)
```

**Proposed Hierarchy:**
```
ModelObject
└── ModelVolumeGroup[] (new)
    └── ModelVolume[] (parts)
```

**Required Changes:**
1. **Backend:**
   - Create `ModelVolumeGroup` class in Model.hpp
   - Add `m_volume_groups` to ModelObject
   - Each group has: name, color, extruder_id, visibility, transformation
   - Volumes reference parent group (optional, null = root level)
   - Serialize/deserialize groups in 3MF format

2. **GUI:**
   - ObjectList tree view: Add group nodes between object and volumes
   - Context menu: "Create Group from Selection", "Ungroup", "Add to Group"
   - Group properties: name, color override, extruder override
   - Drag-drop support: drag volumes into/out of groups

3. **Rendering:**
   - GLCanvas3D: Handle group selection (select all volumes in group)
   - Visual indicator for grouped volumes (bounding box, shared color tint)

**Files Involved:**
- `src/libslic3r/Model.hpp/cpp` - Add ModelVolumeGroup class
- `src/libslic3r/Format/bbs_3mf.cpp` - Serialize groups
- `src/slic3r/GUI/GUI_ObjectList.hpp/cpp` - Add group tree nodes
- `src/slic3r/GUI/GLCanvas3D.cpp` - Group selection/rendering
- `src/slic3r/GUI/Selection.cpp` - Handle group selection

---

### 6. Adjustable Cutting Plane Size

**User Request:**
Increase/decrease the size of the cutting plane. Use case: Non-uniform objects where cutting at specific depth is difficult. Want to resize plane to cut only specific regions without repositioning multiple times.

**Current State:**
✅ **Cutting plane exists:**
- GLGizmoCut3D provides interactive cutting
- Plane position/rotation adjustable
- Plane size is fixed (auto-sized to object bounds)

**Desired Behavior:**
- Adjustable plane dimensions (width, height)
- Allows cutting partial cross-sections
- Useful for complex geometries

**Required Changes:**
1. **Backend:**
   - GLGizmoCut3D: Add m_plane_width, m_plane_height members
   - Modify plane geometry generation to use custom size
   - Cutting logic: Only cut where plane intersects (already may work)

2. **GUI:**
   - ImGUI controls in GLGizmoCut3D::on_render_input_window():
     - Slider: "Plane Width"
     - Slider: "Plane Height"
     - Button: "Reset to Object Size"
   - Visual: Render plane with custom dimensions

3. **Interaction:**
   - Grabbers on plane edges to resize visually
   - Constrain minimum size (prevent zero-size plane)

**Files Involved:**
- `src/slic3r/GUI/Gizmos/GLGizmoCut.hpp/cpp` - Add size controls and rendering
- `src/libslic3r/TriangleMeshSlicer.cpp` - Ensure cutting logic handles partial planes

---

## Notes and Discoveries

**Key Insights:**
1. Feature #1 (per-filament retraction) **already fully implemented** in backend - just needs GUI verification
2. Feature #2 (per-plate settings) is **architecturally significant** - requires reworking Print class
3. Features #3 and #4 (material-specific flushing) are **similar** - both need filament ID arrays
4. Feature #5 (hierarchical grouping) requires **new data structure** (ModelVolumeGroup)
5. Feature #6 (cutting plane size) is **cosmetic/UI** - minimal backend changes

**Implementation Priority (Recommended):**
1. **Quick Win:** Feature #6 (cutting plane) - UI-only, low complexity
2. **High Value:** Features #3 & #4 (material flushing) - solve major pain point, similar implementation
3. **Backend Heavy:** Feature #5 (grouping) - new data structure but well-scoped
4. **Verify:** Feature #1 (retraction) - document existing functionality
5. **Complex:** Feature #2 (per-plate settings) - architectural change, high complexity

**Risks:**
- Per-plate settings (Feature #2) may have cascading impacts on slicing, preview, and device sending
- Hierarchical grouping (Feature #5) requires 3MF format changes (backward compatibility)
- Material-specific flushing (Features #3 & #4) needs careful testing with various material combinations

---

## Notes and Discoveries
*To be filled during exploration*
