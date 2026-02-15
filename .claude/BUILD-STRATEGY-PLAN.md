# OrcaSlicer Build Strategy Plan - 30 Ideas & Implementation
**Created:** 2026-02-14
**Goal:** Successfully build and test OrcaSlicer with all 6 custom features

---

## 🎯 PRIMARY OBJECTIVE

Build OrcaSlicer executable and verify all 6 features work correctly:
1. Per-Filament Retraction (existing)
2. Per-Plate Printer/Filament Settings (675 lines)
3. Prime Tower Filament Selection (32 lines)
4. Support/Infill Flush Selection (32 lines)
5. Hierarchical Volume Grouping (919 lines)
6. Cutting Plane Adjustability (37 lines)

---

## 📊 CURRENT STATUS

- ✅ Code: 100% complete (1,875 lines, 21 files, 0 syntax errors)
- 🔄 Dependencies: 144/187 tasks (77%) - Boost x64 CONFIRMED, OpenCV configuring
- ⏸️ OrcaSlicer Build: Waiting for dependencies
- ⏸️ Testing: Waiting for executable

---

## 🚀 30 BUILD STRATEGY IDEAS

### Category A: Immediate Build Strategies (1-10)

**1. Wait & Build Strategy (CURRENT - RECOMMENDED)**
- Monitor current dependency build (Task b98df4b)
- When complete, verify Boost is x64
- Run build_orcaslicer_x64_safe.bat
- Expected success rate: 95%

**2. Parallel Preparation Strategy**
- While dependencies build, prepare testing environment
- Create test project files for each feature
- Pre-write testing scripts
- Set up benchmarking tools

**3. Incremental Verification Strategy**
- Check every 5 minutes for dependency completion
- Immediately verify critical libraries (Boost, wxWidgets, OCCT)
- Build OrcaSlicer as soon as dependencies ready
- Quick smoke test before full testing

**4. Optimistic Build Strategy**
- Assume dependencies will succeed
- Pre-stage all build commands
- Prepare automated build pipeline
- Execute immediately on completion

**5. Conservative Validation Strategy**
- Wait for full dependency completion
- Run comprehensive validation on all 187 libraries
- Check architecture for all Boost modules
- Only build OrcaSlicer after 100% validation

**6. Fast-Path Build Strategy**
- Use pre-built dependencies if available
- Skip validation checks
- Build immediately
- Fix errors as they come

**7. Staged Build Strategy**
- Build OrcaSlicer core library first (libslic3r)
- Then build GUI library (libslic3r_gui)
- Finally link executable
- Isolate failure points

**8. Minimal Build Strategy**
- Disable optional features temporarily
- Build minimal OrcaSlicer
- Verify base functionality
- Re-enable features incrementally

**9. Clean Slate Strategy**
- After dependencies complete, clean build-x64 directory
- Fresh CMake configure
- Full rebuild from scratch
- Ensures no stale artifacts

**10. Hybrid Build Strategy**
- Use existing deps for non-critical libraries
- Use new x64 deps for critical libraries (Boost)
- Faster build time
- Lower risk

### Category B: Fallback Strategies (11-20)

**11. VS2022 Path Modification**
- Modify user's build_deps_x64.bat to use VS2026
- Use their existing script structure
- Maintain compatibility with their workflow

**12. MSBuild Alternative**
- Use MSBuild instead of Ninja
- Generate VS2026 solution files
- Build through Visual Studio IDE
- Better error messages

**13. Partial Dependency Rebuild**
- Keep working dependencies from previous builds
- Only rebuild Boost with x64
- Faster than full rebuild
- Risk: potential compatibility issues

**14. Static Library Override**
- Manually compile Boost as x64 separately
- Copy libraries to deps location
- Point OrcaSlicer build to new libraries
- Bypass dependency build system

**15. CMAKE_GENERATOR_PLATFORM Strategy**
- Use -A x64 flag with Visual Studio generator
- Force 64-bit platform selection
- Alternative to Ninja approach

**16. Custom CMake Toolchain**
- Create custom toolchain file
- Explicitly set all x64 compilers
- Override any 32-bit detection
- Maximum control

**17. Docker/Container Build**
- Use containerized build environment
- Guaranteed clean environment
- Reproducible builds
- Requires Docker setup

**18. WSL2 Linux Build**
- Build in Windows Subsystem for Linux
- Use Linux build scripts
- Avoid Windows-specific issues
- May need X11 for GUI

**19. Cached Dependency Strategy**
- Download pre-built OrcaSlicer dependencies
- From official releases or CI
- Skip dependency build entirely
- Fastest path to OrcaSlicer build

**20. Incremental Library Build**
- Build only changed libraries
- Use ccache or similar
- Faster iteration
- Requires build cache setup

### Category C: Advanced Strategies (21-25)

**21. Multi-Configuration Build**
- Build both Debug and Release
- Compare outputs
- Debug version for testing
- Release version for performance

**22. Compiler Optimization Strategy**
- Use /O2 optimization flags
- Enable link-time optimization (LTO)
- Faster executable
- Longer build time

**23. Parallel Build Strategy**
- Use all CPU cores (ninja -j)
- Maximize build speed
- Monitor for memory issues
- Fastest possible build

**24. Sanitizer Build Strategy**
- Enable AddressSanitizer
- Catch memory errors
- UndefinedBehaviorSanitizer
- Helps find runtime issues

**25. Profile-Guided Optimization**
- Build instrumented version
- Run typical workload
- Rebuild with profile data
- Maximum performance

### Category D: Testing & Validation Strategies (26-30)

**26. Automated Testing Pipeline**
- Build → Run unit tests → Integration tests → Feature tests
- Automated reporting
- Catch issues early
- Full validation

**27. Feature-Specific Testing**
- Test each of 6 features independently
- Isolated test scenarios
- Clear pass/fail criteria
- Systematic validation

**28. Regression Testing Strategy**
- Test existing OrcaSlicer features
- Ensure no breakage
- Compare with baseline
- Maintain quality

**29. Performance Benchmarking**
- Measure slicing speed
- Memory usage tracking
- Compare with vanilla OrcaSlicer
- Ensure no performance regression

**30. Real-World Testing Strategy**
- Load actual 3D models
- Generate G-code
- Test with multiple printer profiles
- Validate practical functionality

---

## 🎬 IMPLEMENTATION PLAN

### Phase 1: Monitor Current Build (NOW)
**Status:** IN PROGRESS
**Action:**
```bash
# Check every 3 minutes until complete
while true; do
  tail -20 C:\Users\chris\AppData\Local\Temp\claude\J--github-orca-OrcaSlicer\tasks\b98df4b.output
  grep -i "success\|error\|failed" output | tail -5
  sleep 180
done
```

**Success Criteria:**
- All 187 tasks complete
- Message: "Dependencies built successfully!"
- Boost verification shows x64

**If Error:** Apply solution from BUILD-JOURNAL Error Catalog

### Phase 2: Validate Dependencies (NEXT)
**Estimated Time:** 2 minutes
**Actions:**
1. Verify Boost architecture is x64
2. Check wxWidgets built successfully
3. Verify OCCT libraries present
4. Confirm OpenSSL libraries present

**Commands:**
```bash
# Verify Boost is x64
grep -i "x64\|64.*bit" deps/build-x64/OrcaSlicer_dep/usr/local/lib/cmake/boost_filesystem-1.84.0/boost_filesystem-config.cmake

# Check key libraries exist
ls deps/build-x64/OrcaSlicer_dep/usr/local/lib/libboost*.lib | wc -l
ls deps/build-x64/OrcaSlicer_dep/usr/local/lib/*ssl*.lib | wc -l
ls deps/build-x64/OrcaSlicer_dep/usr/local/lib/wx*.lib | wc -l
```

**Success Criteria:**
- Boost config shows x64 or 64-bit
- 10+ Boost libraries present
- SSL libraries present
- wxWidgets libraries present

### Phase 3: Build OrcaSlicer (AFTER PHASE 2)
**Estimated Time:** 10-20 minutes
**Strategy:** #1 (Wait & Build - RECOMMENDED)

**Command:**
```bash
cd /j/github\ orca/OrcaSlicer
./build_orcaslicer_x64_safe.bat
```

**Build will:**
1. Create build-x64 directory
2. Configure CMake with Ninja generator
3. Point to deps/build-x64 dependencies
4. Build libslic3r (core library)
5. Build libslic3r_gui (GUI library)
6. Link OrcaSlicer executable
7. Run gettext for translations
8. Install to build-x64/OrcaSlicer/

**Success Criteria:**
- CMake finds all dependencies
- Compilation completes without errors
- Executable created: build-x64/OrcaSlicer/orca-slicer.exe
- Exit code 0

**If CMake Configuration Fails:**
- Check DEP_BUILD_DIR path is correct
- Verify dependencies are in deps/build-x64
- Try absolute path: -DDEP_BUILD_DIR="J:/github orca/OrcaSlicer/deps/build-x64"

**If Compilation Fails:**
- Read error message for specific file
- Check if it's related to our 6 features
- Search BUILD-JOURNAL for similar error
- Apply documented solution

### Phase 4: Initial Smoke Test (AFTER PHASE 3)
**Estimated Time:** 2 minutes
**Purpose:** Verify executable launches and basic functionality

**Actions:**
```bash
# Launch OrcaSlicer
cd build-x64/OrcaSlicer
./orca-slicer.exe
```

**Success Criteria:**
- Application launches without crash
- Main window appears
- No immediate errors in console
- Can load a simple STL file

**If Crash on Launch:**
- Check for missing DLLs
- Verify dependencies copied to bin/
- Check Windows Event Viewer for crash details
- Try running from VS2026 command prompt

### Phase 5: Feature-Specific Testing (AFTER PHASE 4)
**Estimated Time:** 30-45 minutes
**Purpose:** Systematically test all 6 features

#### Test 5.1: Feature #2 - Per-Plate Settings
**Steps:**
1. Load a project with multiple plates
2. Right-click on a plate
3. Select "Plate Settings" from context menu
4. Change printer preset for that plate
5. Change filament presets for that plate
6. Save project as 3MF
7. Close and reopen project
8. Verify settings persisted

**Success Criteria:**
- Context menu option appears
- Dialog opens without crash
- Can select different presets
- Settings save to 3MF
- Settings load correctly

#### Test 5.2: Feature #5 - Hierarchical Grouping
**Steps:**
1. Load multiple objects
2. Select 2+ objects
3. Right-click → Group
4. Verify group appears in object list
5. Expand/collapse group in tree view
6. Right-click group → Ungroup
7. Verify objects separated

**Success Criteria:**
- Group operation works
- Tree view shows hierarchy
- Group operations in context menu
- Ungroup restores original state

#### Test 5.3: Feature #6 - Cutting Plane
**Steps:**
1. Load an object
2. Activate Cut tool
3. Look for plane size controls
4. Adjust plane width/height
5. Toggle auto-size option
6. Perform cut operation
7. Verify cut successful

**Success Criteria:**
- Plane size controls visible
- Can adjust plane dimensions
- Auto-size toggle works
- Cut operation completes

#### Test 5.4: Feature #3 - Prime Tower Filaments
**Steps:**
1. Set up multi-material print
2. Open Print Settings
3. Find "Prime Tower Filaments" setting
4. Select specific filaments to use
5. Slice the project
6. Check G-code for prime tower
7. Verify only selected filaments used

**Success Criteria:**
- Setting appears in GUI
- Can select/deselect filaments
- Slicing completes
- G-code reflects selection

#### Test 5.5: Feature #4 - Support/Infill Flush
**Steps:**
1. Set up multi-material print
2. Add supports to object
3. Open Print Settings
4. Find "Support Flush Filaments" setting
5. Find "Infill Flush Filaments" setting
6. Configure flush targets
7. Slice and check G-code

**Success Criteria:**
- Both settings appear in GUI
- Can configure flush targets
- Slicing completes
- Flush behavior in G-code

#### Test 5.6: Integration Testing
**Steps:**
1. Use multiple features together
2. Per-plate settings + grouping
3. Cutting plane on grouped objects
4. Multi-material with all flush options
5. Save/load complex project

**Success Criteria:**
- No conflicts between features
- Complex operations work
- Project saves/loads correctly
- No crashes or errors

### Phase 6: Documentation & Completion (AFTER PHASE 5)
**Estimated Time:** 15 minutes

**Actions:**
1. Create TESTING-RESULTS-2026-02-14.md
2. Document all test results (pass/fail)
3. Update BUILD-JOURNAL with final outcome
4. Update PROJECT-STATUS.md
5. Create completion summary

**Deliverables:**
- Test results with screenshots/logs
- Known issues list (if any)
- Performance metrics
- Build time statistics
- Next steps recommendations

---

## 🔄 EXECUTION STRATEGY

### Strategy Selection: #1 (Wait & Build)
**Rationale:**
- Current dependency build progressing well (77% complete)
- Boost x64 confirmed in build output
- No errors detected so far
- Isolated directories prevent collision
- Highest probability of success

### Alternative Strategy if #1 Fails: #9 (Clean Slate)
**Rationale:**
- Start fresh if any artifacts cause issues
- Full clean build from scratch
- Eliminates any potential corruption

### Fallback Strategy if #9 Fails: #13 (Partial Rebuild)
**Rationale:**
- Keep working dependencies
- Only rebuild problematic libraries
- Faster iteration on fixes

---

## 📈 SUCCESS METRICS

### Build Success
- [ ] Dependencies: 187/187 complete
- [ ] Boost: Verified x64 architecture
- [ ] OrcaSlicer: Build completes (exit code 0)
- [ ] Executable: orca-slicer.exe created
- [ ] Launch: Application starts without crash

### Feature Success
- [ ] Feature #2: Per-plate settings work
- [ ] Feature #3: Prime tower filament selection works
- [ ] Feature #4: Support/infill flush works
- [ ] Feature #5: Hierarchical grouping works
- [ ] Feature #6: Cutting plane adjustment works
- [ ] Integration: All features work together

### Quality Metrics
- [ ] No crashes during testing
- [ ] No memory leaks detected
- [ ] Performance acceptable (< 10% slower than baseline)
- [ ] UI responsive
- [ ] G-code generation correct

---

## 🚨 CONTINGENCY PLANS

### If Dependency Build Fails
1. Read error from task output
2. Check BUILD-JOURNAL Error Catalog
3. Apply documented solution
4. Restart dependency build
5. Update journal with new attempt

### If OrcaSlicer Build Fails - CMake Config
1. Verify DEP_BUILD_DIR path
2. Check dependencies exist
3. Try absolute path
4. Verify toolchain setup
5. Check CMakeLists.txt for issues

### If OrcaSlicer Build Fails - Compilation
1. Identify failing file
2. Check if it's one of our 21 modified files
3. Review syntax in that file
4. Check for missing includes
5. Verify feature code is correct

### If Feature Testing Fails
1. Document exact failure
2. Check if code was modified correctly
3. Review implementation plan
4. Test feature in isolation
5. Add debug logging to code
6. Rebuild and retest

---

## 📊 BUILD TIME ESTIMATES

| Phase | Estimated Time | Status |
|-------|----------------|--------|
| Phase 1: Monitor Build | 10-20 min remaining | 🔄 In Progress (77%) |
| Phase 2: Validate Deps | 2 minutes | ⏸️ Waiting |
| Phase 3: Build OrcaSlicer | 10-20 minutes | ⏸️ Waiting |
| Phase 4: Smoke Test | 2 minutes | ⏸️ Waiting |
| Phase 5: Feature Testing | 30-45 minutes | ⏸️ Waiting |
| Phase 6: Documentation | 15 minutes | ⏸️ Waiting |
| **Total Remaining** | **69-104 minutes** | |

**Expected Completion:** 2026-02-14 ~10:30-11:00 (if started at ~9:00)

---

## 🎯 IMMEDIATE NEXT ACTIONS

1. **NOW:** Continue monitoring dependency build (Task b98df4b)
2. **Check every 3 minutes:** tail output for completion
3. **When complete:** Immediately verify Boost x64
4. **Then:** Execute build_orcaslicer_x64_safe.bat
5. **Then:** Begin systematic testing

---

## 📝 NOTES FOR AI AGENTS

**If you're continuing this work:**

1. **Check dependency build status FIRST:**
   ```bash
   tail -50 C:\Users\chris\AppData\Local\Temp\claude\J--github-orca-OrcaSlicer\tasks\b98df4b.output
   ```

2. **Look for completion message:**
   - "Dependencies built successfully!"
   - "OK: Boost is 64-bit"

3. **If complete, proceed to Phase 2** (Validate Dependencies)

4. **If still building, continue monitoring** (Phase 1)

5. **If error, read BUILD-JOURNAL** Error Catalog and apply solution

**Current Task ID:** b98df4b
**Current Progress:** 144/187 (77%)
**Current Phase:** OpenCV configuring
**Expected:** ~10-20 minutes until dependencies complete

---

**Plan Created:** 2026-02-14 ~09:00
**Status:** Phase 1 (Monitor) - IN PROGRESS
**Next Update:** After dependency build completes
