# Planning Session - OrcaSlicer Multi-Extruder Features

## Session Start
Date: 2026-02-13
Focus: Comprehensive multi-extruder feature implementation from Reddit community feedback

## Planning Objectives

### Primary Goal
Research OrcaSlicer architecture and design implementation plan for 6 multi-extruder features requested by the community.

### Research Completed

1. **Source Code Architecture** (70k+ tokens explored)
   - Catalogued 500+ source files across src/libslic3r/ and src/slic3r/GUI/
   - Mapped core slicing engine (Print, GCode, Extruder, ToolOrdering)
   - Documented configuration system (PrintConfig, 1000+ settings)
   - Identified multi-material infrastructure (FilamentGroup, WipeTower, AMS support)

2. **GUI Architecture** (93k+ tokens explored)
   - Mapped wxWidgets-based UI hierarchy (GUI_App → MainFrame → Plater)
   - Documented 3D rendering pipeline (GLCanvas3D, Gizmos, Selection)
   - Analyzed settings system (Tab → Page → ConfigOptionsGroup → Field)
   - Identified object management (ObjectList, ObjectSettings, ObjectLayers)

3. **Multi-Material Systems** (81k+ tokens explored)
   - Extruder switching and retraction mechanisms
   - Prime tower (wipe tower) generation and configuration
   - Flush into object/support/infill logic
   - AMS/MMU filament grouping algorithms
   - Per-filament and per-extruder configuration arrays

### Features Analyzed

#### Feature #1: Per-Filament Retraction Override
**Status:** ✅ Already implemented in backend
**Finding:** All retraction settings exist as per-filament arrays (filament_retraction_length, etc.)
**Action:** Verify GUI exposure and improve discoverability

#### Feature #2: Multi-Per-Plate Settings
**Status:** ❌ Not implemented
**Complexity:** HIGH - Requires architectural changes to Print class
**Action:** Design per-plate config resolution system

#### Feature #3: Prime Tower Material Selection
**Status:** ⚠️ Partial - wipe_tower_filament exists but unclear
**Complexity:** MEDIUM - Extend WipeTower generation
**Action:** Add filament ID arrays for tower and per-object flushing

#### Feature #4: Support Flush Material Selection
**Status:** ⚠️ Basic flush_into_support exists, no per-material control
**Complexity:** MEDIUM - Similar to Feature #3
**Action:** Add support_flush_filaments and infill_flush_filaments arrays

#### Feature #5: Hierarchical Object Grouping
**Status:** ❌ Limited grouping (forces single color)
**Complexity:** MEDIUM - New data structure (ModelVolumeGroup)
**Action:** Implement group layer between ModelObject and ModelVolume

#### Feature #6: Adjustable Cutting Plane Size
**Status:** ✅ Cutting plane exists, fixed size
**Complexity:** LOW - UI-only changes
**Action:** Add width/height sliders to GLGizmoCut3D

### Implementation Plan Created

**Phase 1: Material-Specific Flushing (Features #3 & #4)**
- High value, solves major pain point (incompatible materials mixing)
- Backend: Config options, WipeTower filtering, ToolOrdering constraints
- GUI: CheckListBox for filament selection in tower and flush settings
- Est. 3-5 days

**Phase 2: Cutting Plane Adjustability (Feature #6)**
- Quick win, UI-only changes
- Add plane size controls to GLGizmoCut3D ImGUI
- Est. 1 day

**Phase 3: Hierarchical Object Grouping (Feature #5)**
- New ModelVolumeGroup class
- 3MF serialization extension
- ObjectList tree view updates
- Est. 4-5 days

**Phase 4: Retraction Verification (Feature #1)**
- Verify existing settings are exposed in GUI
- Documentation and tooltip improvements
- Est. 0.5 day

**Phase 5: Per-Plate Settings (Feature #2)**
- Most complex, architectural changes
- Extend PlateData, per-plate config resolution
- Background slicing modifications
- Est. 7-10 days

**Total Estimated Effort:** 16-21 days

### Key Insights

1. **Existing Infrastructure:** OrcaSlicer already has robust multi-material support for up to 64 extruders
2. **Modular Architecture:** Clear separation between libslic3r (engine) and slic3r/GUI (interface)
3. **Configuration System:** Extensible with ConfigOption* classes (Ints, Floats, Bools, Strings)
4. **WipeTower System:** Sophisticated purge tower generation with material-specific parameters
5. **Preset System:** Well-designed for printer/filament/print profiles with inheritance

### Critical Files Identified

**Configuration:**
- src/libslic3r/PrintConfig.hpp/cpp (1000+ settings, 96KB)

**Multi-Material Core:**
- src/libslic3r/GCode/ToolOrdering.cpp (extruder switching, 1694 lines)
- src/libslic3r/GCode/WipeTower.cpp (prime tower generation)
- src/libslic3r/Extruder.cpp (extruder state management)
- src/libslic3r/FilamentGroup.cpp (AMS grouping algorithms)

**Data Model:**
- src/libslic3r/Model.hpp/cpp (ModelObject, ModelVolume)
- src/libslic3r/Print.hpp/cpp (Print orchestration)
- src/libslic3r/PartPlate.hpp/cpp (plate management)

**GUI:**
- src/slic3r/GUI/Plater.cpp (main workspace)
- src/slic3r/GUI/Tab.cpp (settings tabs)
- src/slic3r/GUI/GUI_ObjectList.cpp (object tree view)
- src/slic3r/GUI/Gizmos/GLGizmoCut.cpp (cutting tool)

### Documentation Created

1. **architecture-documentation.md** - Comprehensive codebase analysis
   - Directory structure with file categorization
   - GUI workflow and rendering pipeline
   - Multi-material systems deep dive
   - Per-feature analysis with current state and required changes

2. **humming-nibbling-flask.md** (Plan file) - Implementation plan
   - Context and problem statement
   - Phased implementation approach
   - Detailed technical specifications
   - Testing strategy and verification steps
   - Risk mitigation and success metrics

### Next Steps

User to review and approve implementation plan before proceeding with development.

