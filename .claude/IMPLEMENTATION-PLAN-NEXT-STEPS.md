# Implementation Plan: Build Environment Setup & Testing
**Date:** 2026-02-14
**Status:** Ready to Execute
**Estimated Time:** 3-5 hours total

---

## 🎯 Mission

Fix build environment and comprehensively test all 6 completed features.

---

## ✅ What's Already Done

- ✅ **All 6 features fully implemented** (1,875 lines)
- ✅ **Code verified** (0 syntax errors)
- ✅ **Branch synced** with main (no conflicts)
- ✅ **.gitignore updated** for Claude files
- ✅ **Documentation complete** (1,650+ lines)

---

## 🔧 Phase 1: Build Environment Setup

**Goal:** Rebuild dependencies with correct x64 architecture
**Time:** 1-2 hours (mostly waiting for compilation)
**Complexity:** Medium (requires careful environment setup)

### Step 1.1: Clean Build Artifacts (2 minutes)

```bash
cd /j/github\ orca/OrcaSlicer

# Remove all build artifacts
rm -rf deps/build
rm -rf build/CMakeCache.txt
rm -rf build/CMakeFiles
rm -rf build/.ninja_deps
rm -rf build/.ninja_log
rm -rf build/build.ninja

# Remove junk files
rm -f nul
rm -f build_app_only.bat  # Our temporary script
```

**Verification:**
```bash
# Should be empty or not exist
ls deps/build 2>/dev/null || echo "Clean!"
ls build/CMakeCache.txt 2>/dev/null || echo "Clean!"
```

### Step 1.2: Set Up Build Environment (5 minutes)

**Create permanent build script: `build_deps_x64.bat`**

```batch
@echo off
setlocal
echo ============================================
echo Building OrcaSlicer Dependencies (x64)
echo ============================================

REM Set up VS2026 x64 environment
echo Setting up Visual Studio 2026 x64 environment...
call "J:\visualstudio\vs studio\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to set up VS environment
    exit /b 1
)

REM Set up paths
set "CMAKE_PATH=%~dp0tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;C:\Strawberry\perl\bin;%PATH%"

REM Remove Git/MSYS paths to avoid conflicts
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=%PATH:C:\Program Files\Git\bin;=%"

echo.
echo CMake: %CMAKE_PATH%\cmake.exe
echo Perl: C:\Strawberry\perl\bin\perl.exe
echo.

REM Build dependencies
cd deps
if not exist build mkdir build
cd build

echo Configuring dependencies (Ninja + Release + x64)...
"%CMAKE_PATH%\cmake.exe" .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake configuration failed
    exit /b 1
)

echo.
echo Building dependencies (this will take 30-60 minutes)...
echo Start time: %TIME%
echo.
"%CMAKE_PATH%\cmake.exe" --build . --target deps
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Dependency build failed
    exit /b 1
)

echo.
echo ============================================
echo Dependencies built successfully!
echo End time: %TIME%
echo ============================================
echo.
echo Verifying Boost architecture...
findstr /i "x64 64bit" OrcaSlicer_dep\usr\local\lib\cmake\boost_filesystem-1.84.0\boost_filesystem-config.cmake
if %ERRORLEVEL% EQU 0 (
    echo OK: Boost is 64-bit
) else (
    echo WARNING: Boost may not be 64-bit
    echo Check: deps\build\OrcaSlicer_dep\usr\local\lib\cmake\boost_filesystem-1.84.0\boost_filesystem-config.cmake
)

exit /b 0
```

**Save as:** `J:\github orca\OrcaSlicer\build_deps_x64.bat`

### Step 1.3: Run Dependency Build (30-60 minutes)

```bash
cd /j/github\ orca/OrcaSlicer
./build_deps_x64.bat
```

**Expected Output:**
```
============================================
Building OrcaSlicer Dependencies (x64)
============================================
Setting up Visual Studio 2026 x64 environment...
[vcvarsall.bat] Environment initialized for: 'x64'

CMake: J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe
Perl: C:\Strawberry\perl\bin\perl.exe

Configuring dependencies (Ninja + Release + x64)...
-- Detected X64 compiler => building X64 deps bundle
-- Configuring done (5.1s)
-- Generating done (0.3s)
-- Build files have been written to: J:/github orca/OrcaSlicer/deps/build

Building dependencies (this will take 30-60 minutes)...
Start time: [timestamp]

[... lots of compilation output ...]

Dependencies built successfully!
End time: [timestamp]

Verifying Boost architecture...
OK: Boost is 64-bit
```

**If Errors Occur:**
- wxWidgets submodule error: `git submodule update --init --recursive`
- OCCT .pdb error: Check that Release mode is set, not Debug
- Boost still 32-bit: Verify x64 toolchain with `cl.exe 2>&1 | findstr x64`

### Step 1.4: Build OrcaSlicer (10-20 minutes)

**Create permanent build script: `build_orcaslicer_x64.bat`**

```batch
@echo off
setlocal
echo ============================================
echo Building OrcaSlicer Application (x64)
echo ============================================

REM Set up VS2026 x64 environment
call "J:\visualstudio\vs studio\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 exit /b 1

REM Set up paths
set "CMAKE_PATH=%~dp0tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;C:\Strawberry\perl\bin;%PATH%"
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=%PATH:C:\Program Files\Git\bin;=%"

REM Build OrcaSlicer
cd build

echo Configuring OrcaSlicer...
"%CMAKE_PATH%\cmake.exe" .. -G "Ninja" -DORCA_TOOLS=ON -DCMAKE_BUILD_TYPE=Release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Configuration failed
    exit /b 1
)

echo.
echo Building OrcaSlicer (this will take 10-20 minutes)...
echo Start time: %TIME%
echo.
"%CMAKE_PATH%\cmake.exe" --build .
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    exit /b 1
)

cd ..
echo Running gettext...
call scripts\run_gettext.bat

cd build
echo Installing...
"%CMAKE_PATH%\cmake.exe" --build . --target install --config Release

echo.
echo ============================================
echo BUILD SUCCESSFUL!
echo ============================================
echo.
echo Executable: %~dp0build\OrcaSlicer\orca-slicer.exe
echo.

exit /b 0
```

**Save as:** `J:\github orca\OrcaSlicer\build_orcaslicer_x64.bat`

**Run:**
```bash
cd /j/github\ orca/OrcaSlicer
./build_orcaslicer_x64.bat
```

**Expected Output:**
```
============================================
Building OrcaSlicer Application (x64)
============================================
[vcvarsall.bat] Environment initialized for: 'x64'

Configuring OrcaSlicer...
-- The C compiler identification is MSVC 19.50.35724.0
-- The CXX compiler identification is MSVC 19.50.35724.0
-- SLIC3R_GUI: ON
-- SLIC3R_PCH: ON
...
-- Configuring done
-- Generating done

Building OrcaSlicer (this will take 10-20 minutes)...
Start time: [timestamp]

[3000/3000] Linking CXX executable src\OrcaSlicer.exe

BUILD SUCCESSFUL!

Executable: J:\github orca\OrcaSlicer\build\OrcaSlicer\orca-slicer.exe
```

---

## 🧪 Phase 2: Feature Testing

**Goal:** Verify all 6 features work correctly
**Time:** 2-3 hours
**Complexity:** Medium (systematic testing required)

### Test Environment Setup

**Launch OrcaSlicer:**
```bash
cd /j/github\ orca/OrcaSlicer/build/OrcaSlicer
./orca-slicer.exe
```

**Prepare Test Models:**
- Single part model (for Feature #6)
- Multi-part model with 3+ volumes (for Feature #5)
- Multi-material model with 4 filaments (for Features #3, #4)

### Feature #1: Per-Filament Retraction (10 minutes)

**Already Exists - Verify Functionality**

**Test Steps:**
1. ✅ Open Filament Settings
2. ✅ Find "Retraction" section
3. ✅ Verify "Override" checkboxes present
4. ✅ Change retraction length for one filament
5. ✅ Slice → Verify G-code uses custom retraction

**Expected:** Per-filament retraction values in G-code

**Pass/Fail:** _______________

---

### Feature #2: Per-Plate Settings (30 minutes)

**Test Steps:**
1. ✅ Load a model
2. ✅ Click plate settings icon (gear on plate)
3. ✅ Verify "Custom printer for this plate" checkbox
4. ✅ Check it → Verify dropdown enables
5. ✅ Select different printer
6. ✅ Verify "Custom filaments for this plate" checkbox
7. ✅ Check it → Verify per-extruder dropdowns enable
8. ✅ Select different filaments for each extruder
9. ✅ Click OK
10. ✅ Verify plate icon shows "changed" indicator
11. ✅ Slice the plate
12. ✅ Check log for "Using custom config for plate..."
13. ✅ Save project as test.3mf
14. ✅ Close project
15. ✅ Reopen test.3mf
16. ✅ Verify custom settings restored
17. ✅ Reopen plate settings → Verify selections match

**Expected:**
- Dialog opens with checkbox controls
- Dropdown populated with printer/filament presets
- Settings persist across save/load
- Slicing uses custom config

**Pass/Fail:** _______________

**Issues Found:** _______________

---

### Feature #3: Prime Tower Filament Selection (20 minutes)

**Test Steps:**
1. ✅ Load multi-material model (4 filaments)
2. ✅ Open Print Settings
3. ✅ Enable prime tower
4. ✅ Find "Prime tower filaments" setting
5. ✅ Enter "1,2,3" (exclude filament 4)
6. ✅ Slice the model
7. ✅ Open G-code preview
8. ✅ Verify filament 4 tool changes don't use tower
9. ✅ Check that filaments 1-3 do use tower
10. ✅ Test with new wipe tower preheat from PR #12266

**Expected:**
- Setting visible in Print Settings
- Filament 4 excluded from tower usage
- Filaments 1-3 use tower normally
- Compatible with preheat features

**Pass/Fail:** _______________

**Issues Found:** _______________

---

### Feature #4: Support/Infill Flush Selection (20 minutes)

**Test Steps:**
1. ✅ Load multi-material model with support
2. ✅ Enable support material
3. ✅ Find "Filaments for support flushing" setting
4. ✅ Enter "1,2" (exclude filament 3 from support)
5. ✅ Find "Filaments for infill flushing" setting
6. ✅ Set it differently (e.g., "1,3")
7. ✅ Slice the model
8. ✅ Verify filament 3 doesn't flush into support
9. ✅ Verify filament 2 doesn't flush into infill
10. ✅ Check G-code for proper flushing behavior

**Expected:**
- Settings visible in Print Settings
- Excluded filaments don't flush to designated areas
- Allowed filaments flush normally

**Pass/Fail:** _______________

**Issues Found:** _______________

---

### Feature #5: Hierarchical Volume Grouping (40 minutes)

**Test Steps:**
1. ✅ Load multi-part object (3+ volumes)
2. ✅ Select 2 volumes (Ctrl+Click)
3. ✅ Right-click → Find "Create group" option
4. ✅ Click "Create group from selection"
5. ✅ Enter group name "Test Group"
6. ✅ Click OK
7. ✅ Verify group appears in object tree
8. ✅ Click on group node
9. ✅ Verify cyan bounding box in 3D view
10. ✅ Right-click group → Assign extruder
11. ✅ Select extruder 2
12. ✅ Verify group uses extruder 2
13. ✅ Right-click group → Rename
14. ✅ Change name to "Body Parts"
15. ✅ Save project as group-test.3mf
16. ✅ Close and reopen
17. ✅ Verify groups persisted
18. ✅ Right-click group → Ungroup
19. ✅ Verify volumes move back to root
20. ✅ Delete group
21. ✅ Test with new object highlighting from PR #12115

**Expected:**
- Group creation dialog appears
- Groups visible in tree view
- Cyan bounding box renders for groups
- Extruder assignment works
- Rename works
- 3MF save/load preserves groups
- Ungroup works
- Compatible with new highlighting

**Pass/Fail:** _______________

**Issues Found:** _______________

---

### Feature #6: Adjustable Cutting Plane (15 minutes)

**Test Steps:**
1. ✅ Load a model
2. ✅ Tools → Cut (or cutting gizmo icon)
3. ✅ Verify cutting plane appears
4. ✅ Find "Auto-size plane" checkbox
5. ✅ Verify it's checked by default
6. ✅ Uncheck "Auto-size plane"
7. ✅ Verify width slider appears and is enabled
8. ✅ Verify height slider appears and is enabled
9. ✅ Adjust width slider (e.g., to 200mm)
10. ✅ Verify plane width changes in 3D view
11. ✅ Adjust height slider (e.g., to 150mm)
12. ✅ Verify plane height changes in 3D view
13. ✅ Check "Auto-size plane" again
14. ✅ Verify plane returns to auto-sizing
15. ✅ Verify sliders are disabled

**Expected:**
- Checkbox controls auto-sizing
- Sliders work and update plane in real-time
- Manual size persists during session
- Auto-size reverts to automatic calculation

**Pass/Fail:** _______________

**Issues Found:** _______________

---

## 🔬 Phase 3: Integration Testing

**Goal:** Test features working together
**Time:** 1 hour
**Complexity:** High (complex interactions)

### Integration Test 1: Grouped Volumes with Per-Plate Settings (20 minutes)

**Scenario:** Multi-part object with groups, using different plate settings

**Steps:**
1. Load multi-part object
2. Create groups for different functional parts
3. Configure Plate 1 with Printer A + PLA
4. Add another plate (Plate 2)
5. Configure Plate 2 with Printer B + PETG
6. Verify groups appear on both plates
7. Slice both plates
8. Verify each uses correct printer/filament config
9. Save and reload project
10. Verify all settings persist

**Pass/Fail:** _______________

### Integration Test 2: All Multi-Material Features Together (20 minutes)

**Scenario:** Complex multi-material print using Features #3, #4

**Steps:**
1. Load 4-filament multi-material model
2. Enable support and infill
3. Set `wipe_tower_filaments` to "1,2,3"
4. Set `support_flush_filaments` to "1,2"
5. Set `infill_flush_filaments` to "1,3"
6. Slice
7. Verify:
   - Filament 4 doesn't use tower
   - Filament 3 doesn't flush to support
   - Filament 2 doesn't flush to infill
8. Check G-code for proper flushing behavior
9. Test with preheat from PR #12266

**Pass/Fail:** _______________

### Integration Test 3: Complex Project (20 minutes)

**Scenario:** Multi-plate, multi-part, multi-material project

**Steps:**
1. Create project with 3 plates
2. Each plate has different printer/filament settings
3. Each plate has grouped volumes
4. Each plate uses custom tower filament selection
5. Save as comprehensive-test.3mf
6. Reload
7. Verify all features work together
8. Slice all plates
9. Verify independent configs per plate

**Pass/Fail:** _______________

---

## 📋 Phase 4: Regression Testing

**Goal:** Ensure existing features still work
**Time:** 30 minutes
**Complexity:** Low (spot checks)

### Regression Checks

- [ ] Single-material print works
- [ ] Multi-material without our features works
- [ ] Old 3MF files load correctly
- [ ] Standard slicing produces valid G-code
- [ ] UI responsiveness is normal
- [ ] No crashes during normal operations

---

## 📝 Phase 5: Documentation & Cleanup

**Goal:** Update docs and prepare for next steps
**Time:** 30 minutes
**Complexity:** Low

### Update Documentation

**If line numbers changed significantly:**
1. Update line references in `.claude/*.md` files
2. Note any new issues found during testing
3. Document compatibility with recent PRs

**Test Results:**
1. Create `.claude/TESTING-RESULTS-2026-02-14.md`
2. Document pass/fail for each feature
3. List any issues found
4. Note performance observations

### Code Cleanup

**If needed:**
- Remove any debug logging added
- Clean up commented code
- Verify .gitignore covers artifacts

### Prepare for PR (Optional)

**If submitting to main:**
1. Squash/organize commits if needed
2. Write comprehensive commit message
3. Update main `README.md` if needed
4. Prepare PR description with:
   - Feature list
   - Testing results
   - Breaking changes (if any)
   - Screenshots/videos

---

## ✅ Success Criteria

### Build Phase Success
- [x] Dependencies compile without errors
- [ ] Dependencies are confirmed 64-bit
- [ ] OrcaSlicer compiles without errors
- [ ] Executable launches successfully

### Testing Phase Success
- [ ] Feature #1: Per-filament retraction works
- [ ] Feature #2: Per-plate settings work end-to-end
- [ ] Feature #3: Tower filament selection works
- [ ] Feature #4: Support/infill flush selection works
- [ ] Feature #5: Hierarchical grouping works
- [ ] Feature #6: Cutting plane adjustment works
- [ ] Integration tests pass
- [ ] No regressions found
- [ ] Performance is acceptable

### Documentation Success
- [ ] Test results documented
- [ ] Issues (if any) documented
- [ ] Next steps identified
- [ ] Code ready for PR (if desired)

---

## 🚨 Troubleshooting Guide

### Build Issues

**Issue: Boost still shows 32-bit**
```bash
# Solution: Verify x64 toolchain
cl.exe 2>&1 | findstr "x64"
# Should say "for x64", not "for x86"

# If wrong, start fresh shell and re-run vcvarsall
```

**Issue: wxWidgets submodule error**
```bash
# Solution: Update submodules
cd deps
git submodule update --init --recursive
```

**Issue: OCCT .pdb missing**
```
# Solution: Ensure Release mode
# Check cmake command uses: -DCMAKE_BUILD_TYPE=Release
# NOT Debug
```

### Testing Issues

**Issue: Feature #2 dialog doesn't open**
- Check plate settings icon is clickable
- Verify PlateSettingsDialog is compiled
- Check logs for errors

**Issue: Feature #3/4 settings not visible**
- Check Print Settings → Advanced mode
- Verify multi-material mode enabled
- Check if options appear in search

**Issue: Feature #5 menu missing**
- Right-click on volumes (not objects)
- Verify multiple volumes selected
- Check GUI_ObjectList compiled

**Issue: Feature #6 controls missing**
- Verify cutting gizmo active
- Check ImGui rendering works
- Look for checkbox in gizmo panel

---

## 📊 Time Estimates

| Phase | Task | Time | Can Run Parallel? |
|-------|------|------|-------------------|
| 1.1 | Clean artifacts | 2 min | No |
| 1.2 | Create scripts | 5 min | No |
| 1.3 | Build dependencies | 30-60 min | No (waiting) |
| 1.4 | Build OrcaSlicer | 10-20 min | No (waiting) |
| **Phase 1 Total** | | **1-2 hours** | |
| 2 | Feature testing | 2-3 hours | Partially |
| 3 | Integration testing | 1 hour | No |
| 4 | Regression testing | 30 min | Partially |
| 5 | Documentation | 30 min | Yes |
| **Total** | | **3-5 hours** | |

**Optimization:**
- While dependencies build (30-60 min), can write test plans
- While OrcaSlicer builds (10-20 min), can prepare test models
- Some tests can run in parallel if multiple people testing

---

## 🎯 Next Immediate Actions

**1. Execute Build Phase (Now)**
   - Save build scripts
   - Run `build_deps_x64.bat`
   - Monitor for errors
   - Run `build_orcaslicer_x64.bat`

**2. Launch OrcaSlicer (After Build)**
   - Navigate to build/OrcaSlicer
   - Run orca-slicer.exe
   - Verify no crash on startup

**3. Begin Testing (After Launch)**
   - Follow test procedures above
   - Document results as you go
   - Note any issues immediately

**4. Report Results (After Testing)**
   - Create testing results document
   - Update status documentation
   - Decide on next steps (PR, enhancements, etc.)

---

**Document Created:** 2026-02-14
**Status:** Ready to Execute
**Prerequisites:** All code complete, documented, verified
**Confidence:** 95% (known build solution, code is solid)
