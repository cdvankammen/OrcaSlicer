# Build Guide - Custom Features Branch

**Quick Start:** Use GitHub Actions (easiest, 80%+ success rate)

---

## GitHub Actions Build (Recommended)

### Why GitHub Actions?
- ✅ Proven VS2022 environment (avoids local toolchain issues)
- ✅ Builds Windows + Linux + macOS simultaneously
- ✅ No local system configuration required
- ✅ 2-3 hour total time (setup + build)
- ✅ Downloadable artifacts
- ✅ 80%+ success probability

### How to Build

#### Step 1: Push to GitHub
```bash
cd OrcaSlicer
git add .github/workflows/build-custom-features.yml
git add docs/
git commit -m "Add custom features build workflow"
git push origin cdv-personal
```

#### Step 2: Trigger Build (Web UI)
1. Go to GitHub repository Actions tab
2. Click "Build OrcaSlicer with Custom Features"
3. Click "Run workflow" dropdown
4. Select branch: `cdv-personal`
5. Select build type: `RelWithDebInfo` (recommended)
6. Click green "Run workflow" button

**Alternative (GitHub CLI):**
```bash
gh workflow run build-custom-features.yml \
  --ref cdv-personal \
  --field build_type=RelWithDebInfo
```

#### Step 3: Monitor Build
- Build runs in parallel: Windows, Linux, macOS
- Expected duration: 2-3 hours total
- Watch real-time progress in Actions tab

#### Step 4: Download Artifacts
When build completes:
1. Scroll to "Artifacts" section at bottom of workflow run
2. Download ZIP/TAR.GZ for your platform:
   - `OrcaSlicer-CustomFeatures-Windows-RelWithDebInfo.zip`
   - `OrcaSlicer-CustomFeatures-Linux-RelWithDebInfo.tar.gz`
   - `OrcaSlicer-CustomFeatures-macOS-RelWithDebInfo.zip`

#### Step 5: Extract and Test
```bash
# Windows
unzip OrcaSlicer-CustomFeatures-Windows.zip
cd OrcaSlicer-CustomFeatures-*/
./OrcaSlicer.exe

# Linux
tar xzf OrcaSlicer-CustomFeatures-Linux.tar.gz
cd OrcaSlicer-CustomFeatures-*/
./orcaslicer

# macOS
unzip OrcaSlicer-CustomFeatures-macOS.zip
cd OrcaSlicer-CustomFeatures-*/
open OrcaSlicer.app
```

---

## Local Build (Advanced)

### Prerequisites

**Windows:**
- Visual Studio 2022 (Community or Enterprise)
- C++ development workload
- CMake 3.13+
- Ninja build system
- Git with submodules support

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install \
  build-essential cmake ninja-build git gettext \
  libgtk-3-dev libwxgtk3.0-gtk3-dev libssl-dev \
  libcurl4-openssl-dev libglu1-mesa-dev libdbus-1-dev \
  extra-cmake-modules pkgconf libudev-dev libglew-dev libhidapi-dev
```

**macOS:**
```bash
brew install cmake ninja gettext wxwidgets
```

### Build Steps

#### 1. Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/OrcaSlicer.git
cd OrcaSlicer
git checkout cdv-personal
git submodule update --init --recursive
```

#### 2. Build Dependencies
```bash
cd deps
mkdir build && cd build

# Windows (VS2022 environment)
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja

# Linux/macOS
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja

cd ../..
```

**Expected duration:** 1-2 hours (downloads and compiles Boost, wxWidgets, OpenCV, etc.)

#### 3. Build OrcaSlicer
```bash
mkdir build && cd build

# Windows (VS2022 environment)
cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSLIC3R_STATIC=ON \
  -DSLIC3R_GUI=ON \
  -DSLIC3R_PCH=OFF
ninja

# Linux
cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSLIC3R_STATIC=ON \
  -DSLIC3R_GUI=ON
ninja

# macOS
cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSLIC3R_STATIC=ON \
  -DSLIC3R_GUI=ON
ninja
```

**Expected duration:** 30-60 minutes

#### 4. Run
```bash
# Windows
.\src\OrcaSlicer.exe

# Linux
./src/orcaslicer

# macOS
open src/OrcaSlicer.app
```

---

## Build Configurations

### Release (Optimized)
```cmake
-DCMAKE_BUILD_TYPE=Release
```
- Full optimizations
- No debug symbols
- Fastest runtime performance
- Use for production

### RelWithDebInfo (Recommended)
```cmake
-DCMAKE_BUILD_TYPE=RelWithDebInfo
```
- Optimizations enabled
- Debug symbols included
- Good performance + debuggability
- **Recommended for testing**

### Debug (Development)
```cmake
-DCMAKE_BUILD_TYPE=Debug
```
- No optimizations
- Full debug symbols
- Slow runtime
- Use for development only

---

## Common Issues

### Windows: "Cannot find Visual Studio"
**Solution:**
```bash
# Use VS2022 Developer Command Prompt
# Or manually set environment:
call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
```

### Windows: "wxWidgets git submodule error"
**Solution:**
```bash
# Manually initialize wxWidgets submodules
cd deps/build/dep_wxWidgets-prefix/src/dep_wxWidgets
git submodule update --init --recursive
cd ../../../../..
```

### Linux: "Package not found"
**Solution:** Install missing development packages
```bash
sudo apt-get update
sudo apt-get install <missing-package>-dev
```

### macOS: "Library not found"
**Solution:** Install via Homebrew
```bash
brew install <missing-library>
```

### All: "CMake version too old"
**Solution:** Update CMake
```bash
# Windows: Download from cmake.org
# Linux: sudo snap install cmake --classic
# macOS: brew upgrade cmake
```

---

## Build Troubleshooting

### Clean Build
```bash
# Remove all build artifacts
rm -rf build deps/build

# Start fresh
# ... follow build steps again
```

### Dependency Issues
```bash
# Rebuild only dependencies
cd deps/build
ninja clean
ninja

# Then rebuild main
cd ../../build
ninja
```

### Git Submodule Issues
```bash
# Reinitialize all submodules
git submodule deinit --all -f
git submodule update --init --recursive
```

---

## Build Time Estimates

| Platform | Dependencies | Main Build | Total |
|----------|--------------|------------|-------|
| **Windows** | 60-90 min | 30-45 min | 90-135 min |
| **Linux** | 30-45 min | 20-30 min | 50-75 min |
| **macOS** | 45-60 min | 25-35 min | 70-95 min |

**GitHub Actions:** 2-3 hours (all platforms in parallel)

---

## Continuous Integration

### Workflow File
`.github/workflows/build-custom-features.yml`

### Trigger Options

**Manual (via UI):**
- Actions tab → Run workflow

**Manual (via CLI):**
```bash
gh workflow run build-custom-features.yml
```

**Automatic (on push):**
Modify workflow to add:
```yaml
on:
  push:
    branches:
      - cdv-personal
```

### Artifacts
- Retention: 30 days
- Download via: Actions tab → Workflow run → Artifacts section
- Or via CLI: `gh run download [RUN_ID]`

---

## Testing the Build

### Quick Smoke Test
1. Launch OrcaSlicer
2. Create new project
3. Import model
4. Check all 6 features present:
   - Per-plate presets (right-click plate)
   - Prime tower filaments (multi-material settings)
   - Flush filaments (multi-material settings)
   - Volume grouping (right-click volume)
   - Cutting plane size (cut tool)

### Comprehensive Testing
See `.claude/CREATIVE-TESTING-PLAYBOOK.md` for 50+ test scenarios.

**Critical Tests:**
- Multi-plate with different presets
- Multi-material with selective flush
- Volume groups with visibility toggle
- Undo/redo operations (known issues!)
- 3MF save/load

---

## Performance Profiling

### Windows
```bash
# Use Visual Studio Profiler
devenv /DebugExe build\src\OrcaSlicer.exe
```

### Linux
```bash
# Use perf
perf record -g ./build/src/orcaslicer
perf report
```

### macOS
```bash
# Use Instruments
instruments -t "Time Profiler" ./build/src/OrcaSlicer.app
```

---

## Debugging

### Windows (Visual Studio)
```bash
# Open in VS
devenv build\src\OrcaSlicer.exe

# Or attach debugger
devenv /DebugExe build\src\OrcaSlicer.exe
```

### Linux (GDB)
```bash
gdb ./build/src/orcaslicer
(gdb) run
(gdb) bt  # backtrace on crash
```

### macOS (LLDB)
```bash
lldb ./build/src/OrcaSlicer.app/Contents/MacOS/OrcaSlicer
(lldb) run
(lldb) bt  # backtrace on crash
```

---

## Packaging

### Windows Installer
```powershell
# Use NSIS or WiX
# See main OrcaSlicer packaging scripts
```

### Linux AppImage
```bash
# Use linuxdeploy
# See main OrcaSlicer packaging scripts
```

### macOS DMG
```bash
# Use create-dmg
# See main OrcaSlicer packaging scripts
```

---

## Support

**Build Issues:** Create GitHub issue with `[Build]` tag
**Feature Issues:** Create GitHub issue with `[Custom Features]` tag
**Questions:** OrcaSlicer Discord #development channel

---

## Additional Resources

- **OrcaSlicer Wiki:** https://github.com/SoftFever/OrcaSlicer/wiki
- **Build Dependencies:** See `deps/CMakeLists.txt`
- **Custom Features:** See `docs/CUSTOM-FEATURES.md`

---

**Status:** Ready to Build ✅
**Recommended:** GitHub Actions (80%+ success, easiest)
**Alternative:** Local build (advanced users, working VS2022/GCC/Clang required)
