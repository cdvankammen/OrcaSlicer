# Additional Build Strategies - Creative Approaches

**Goal:** Fix local build environment through creative solutions

**Priority Order:**
1. 🥇 GitHub Actions (already set up) - **DO THIS FIRST**
2. 🥈 WSL2 Linux (quick fix) - **BEST LOCAL OPTION**
3. 🥉 Install VS2022 (reliable) - **IF YOU WANT WINDOWS NATIVE**
4. 🔧 Fix VS2026 (experimental) - **LAST RESORT**

---

## Strategy 1: WSL2 Linux Build (RECOMMENDED)

**Why:** Fast, reliable, OrcaSlicer's primary platform

**Time:** 1 hour (after restart)
**Success Probability:** 85%
**Difficulty:** Easy

### Step 1: Enable WSL2

```powershell
# Run PowerShell as Administrator
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart computer
shutdown /r /t 0
```

### Step 2: Set WSL2 as Default and Start Ubuntu

```bash
# After restart
wsl --set-default-version 2

# Start Ubuntu
wsl --distribution Ubuntu

# You should now be in Ubuntu shell
```

### Step 3: Install Build Dependencies

```bash
# Update package list
sudo apt-get update

# Install all dependencies
sudo apt-get install -y \
  build-essential \
  cmake \
  ninja-build \
  git \
  gettext \
  libgtk-3-dev \
  libwxgtk3.0-gtk3-dev \
  libssl-dev \
  libcurl4-openssl-dev \
  libglu1-mesa-dev \
  libdbus-1-dev \
  extra-cmake-modules \
  pkgconf \
  libudev-dev \
  libglew-dev \
  libhidapi-dev
```

### Step 4: Navigate to Project (Windows Drive Accessible)

```bash
# Windows drives are mounted at /mnt/
cd /mnt/j/github\ orca/OrcaSlicer

# Or create symlink for easier access
ln -s /mnt/j/github\ orca/OrcaSlicer ~/orcaslicer
cd ~/orcaslicer
```

### Step 5: Build

```bash
# Build dependencies
cd deps
mkdir -p build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja

# Build OrcaSlicer
cd ../..
mkdir -p build && cd build
cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSLIC3R_STATIC=ON \
  -DSLIC3R_GUI=ON
ninja

# Executable will be at: build/src/orcaslicer
```

**Time Breakdown:**
- Enable WSL2: 5 minutes
- Restart: 5 minutes
- Install dependencies: 10 minutes
- Build deps: 30-45 minutes
- Build OrcaSlicer: 20-30 minutes
- **Total:** ~1 hour

**Pros:**
- ✅ Uses proven Linux toolchain
- ✅ All dependencies available via apt
- ✅ No VS2026 issues
- ✅ Faster than Windows build
- ✅ Can access Windows files easily

**Cons:**
- 🔄 Requires restart
- 🐧 Unfamiliar if new to Linux
- 🖥️ Produces Linux executable (not Windows .exe)

---

## Strategy 2: Install VS2022 Alongside VS2026

**Why:** Official OrcaSlicer toolchain, stable, proven

**Time:** 2-3 hours
**Success Probability:** 80%
**Difficulty:** Medium

### Step 1: Download VS2022

1. Go to: https://visualstudio.microsoft.com/vs/
2. Download "Visual Studio 2022 Community" (free)
3. Run installer

### Step 2: Select Workloads

During installation, select:
- ✅ **Desktop development with C++** (required)
  - ✅ MSVC v143 - VS 2022 C++ x64/x86 build tools
  - ✅ C++ CMake tools for Windows
  - ✅ Windows 10/11 SDK

**Download Size:** ~8GB
**Install Time:** 30-60 minutes

### Step 3: Verify Installation

```bash
# Open VS2022 Developer Command Prompt
# (Start menu → Visual Studio 2022 → Developer Command Prompt)

# Check compiler
where cl.exe

# Check C++ headers
dir "%VCToolsInstallDir%\include\cstddef"
```

**Expected:** File found

### Step 4: Clean and Rebuild

```bash
# Navigate to project
cd "J:\github orca\OrcaSlicer"

# Clean previous attempts
rm -rf deps/build* build*

# Build dependencies (in VS2022 Developer Command Prompt)
cd deps
mkdir build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja

# Build OrcaSlicer
cd ..\..
mkdir build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja
```

**Time Breakdown:**
- Download: 30 minutes
- Install: 30-60 minutes
- Clean: 2 minutes
- Build deps: 60-90 minutes
- Build OrcaSlicer: 30-45 minutes
- **Total:** 2.5-3.5 hours

**Pros:**
- ✅ Official OrcaSlicer toolchain
- ✅ Stable, not experimental
- ✅ Proven working environment
- ✅ Produces Windows .exe
- ✅ Can keep VS2026 for other projects

**Cons:**
- ⏰ Large download + install time
- 💾 ~20GB disk space
- 🔧 Need to use VS2022 command prompt

---

## Strategy 3: Fix VS2026 Installation

**Why:** Use desired VS2026 version

**Time:** 2-3 hours
**Success Probability:** 70%
**Difficulty:** Medium

### Step 1: Uninstall VS2026 Completely

1. Control Panel → Programs and Features
2. Find "Visual Studio 2026" or similar
3. Uninstall completely
4. Restart computer

### Step 2: Download Latest VS2026

- Check for latest installer
- Ensure it's stable release (not preview/beta)

### Step 3: Install with Correct Components

**Critical:** Select these components:
- ✅ **Desktop development with C++** (required)
  - ✅ MSVC v145 - VS 2026 C++ build tools
  - ✅ C++ core features
  - ✅ C++ CMake tools for Windows
  - ✅ Windows 10/11 SDK
  - ✅ **C++ standard library** (ensure checked!)

### Step 4: Verify C++ Headers Exist

```bash
# After install, check headers
dir "J:\Visual Studio\VS Studio\VC\Tools\MSVC\14.50.34357\include\cstddef"

# Or wherever VS2026 installed
dir "%VCToolsInstallDir%\include\cstddef"
```

**Expected:** File must exist!

### Step 5: Rebuild

```bash
# Open VS2026 Developer Command Prompt
cd "J:\github orca\OrcaSlicer"

# Clean previous attempts
rm -rf deps/build* build*

# Rebuild
cd deps
mkdir build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja
```

**Time Breakdown:**
- Uninstall: 10 minutes
- Restart: 5 minutes
- Download: 30 minutes
- Install: 30-60 minutes
- Verify: 2 minutes
- Build deps: 60-90 minutes
- Build OrcaSlicer: 30-45 minutes
- **Total:** 2.5-3.5 hours

**Pros:**
- ✅ Uses desired VS2026
- ✅ May have latest features

**Cons:**
- ❓ VS2026 may be experimental/unstable
- ⏰ Large download + install time
- 💾 ~20GB disk space
- ⚠️ No guarantee it will work (70% probability)

---

## Strategy 4: Use MinGW-w64 (Alternative Compiler)

**Why:** Free, lightweight, no VS required

**Time:** 1-2 hours
**Success Probability:** 60%
**Difficulty:** Hard (requires CMake changes)

### Step 1: Install MinGW-w64

1. Download from: https://winlibs.com/
2. Extract to `C:\mingw64\`
3. Add to PATH: `C:\mingw64\bin`

### Step 2: Install CMake and Ninja

```bash
choco install cmake ninja
```

### Step 3: Modify CMake Files (May Need Changes)

MinGW may require toolchain file adjustments. OrcaSlicer is designed for MSVC, so this is experimental.

### Step 4: Build

```bash
cd "J:\github orca\OrcaSlicer"

# Set compiler
set CC=gcc
set CXX=g++

# Build
cd deps
mkdir build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja
```

**Pros:**
- ✅ Free and lightweight
- ✅ No Visual Studio needed
- ✅ GCC compiler (Linux-like)

**Cons:**
- ⚠️ OrcaSlicer not designed for MinGW
- 🔧 May need extensive CMake changes
- ❓ 60% success probability
- 🐛 Potential compatibility issues

---

## Strategy 5: Use Clang/LLVM

**Why:** Modern compiler, good Windows support

**Time:** 1-2 hours
**Success Probability:** 65%
**Difficulty:** Hard

### Step 1: Install Clang

```bash
choco install llvm
```

### Step 2: Build

```bash
set CC=clang
set CXX=clang++

cd "J:\github orca\OrcaSlicer\deps"
mkdir build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja
```

**Similar issues as MinGW** - OrcaSlicer designed for MSVC.

---

## Strategy 6: Use Pre-built Dependencies

**Why:** Skip dependency building entirely

**Time:** 30 minutes + main build
**Success Probability:** 75%
**Difficulty:** Medium

### Step 1: Download Pre-built Deps

Check if OrcaSlicer provides pre-built dependency packages:
- Official releases may include deps
- Community may share pre-built deps

### Step 2: Extract and Point CMake

```bash
# Extract deps to: J:\github orca\OrcaSlicer\deps\build\

# Build only main project
cd "J:\github orca\OrcaSlicer"
mkdir build && cd build
cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DDEP_WX_WIDGETS_DIR="J:\github orca\OrcaSlicer\deps\build\dep_wxWidgets" \
  ...
ninja
```

**Issue:** Still needs C++ headers for main project compilation.

---

## Strategy 7: Docker Build on Windows

**Why:** Isolated environment, reproducible

**Time:** 1-2 hours (after Docker install)
**Success Probability:** 80%
**Difficulty:** Medium

### Prerequisites

```bash
# Install Docker Desktop (see LOCAL-ACTIONS-GUIDE.md)
```

### Create Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential cmake ninja-build git gettext \
    libgtk-3-dev libwxgtk3.0-gtk3-dev libssl-dev \
    libcurl4-openssl-dev libglu1-mesa-dev libdbus-1-dev \
    extra-cmake-modules pkgconf libudev-dev libglew-dev libhidapi-dev

WORKDIR /build
COPY . /build

RUN cd deps && mkdir -p build && cd build && \
    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    ninja

RUN mkdir -p build && cd build && \
    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DSLIC3R_STATIC=ON -DSLIC3R_GUI=ON && \
    ninja
```

### Build in Docker

```bash
cd "J:\github orca\OrcaSlicer"

# Build image
docker build -t orcaslicer-builder .

# Copy executable out
docker run --rm orcaslicer-builder tar -czf - build/src/ | tar -xzf -
```

**Pros:**
- ✅ Isolated environment
- ✅ Uses Linux toolchain (reliable)
- ✅ Reproducible
- ✅ No local system changes

**Cons:**
- 🐳 Requires Docker (20GB+)
- 🐧 Produces Linux executable
- ⏰ Slow first build

---

## Strategy 8: Remote Build Server

**Why:** Use someone else's working environment

**Time:** Variable
**Success Probability:** 90%
**Difficulty:** Easy

### Option A: Ask Community

1. Post in OrcaSlicer Discord #build-help:
   ```
   I have code ready but broken local environment.
   Can someone build branch `cdv-personal` from my fork?
   Fork: https://github.com/YOUR_USERNAME/OrcaSlicer
   ```

2. Share your fork/branch
3. Someone builds and shares executable

### Option B: Use CI Service

- Travis CI
- CircleCI
- Azure Pipelines
- Jenkins (self-hosted)

All similar to GitHub Actions but different providers.

---

## Strategy 9: Virtual Machine with Working Environment

**Why:** Fresh, clean environment

**Time:** 2-3 hours (setup)
**Success Probability:** 85%
**Difficulty:** Medium

### Step 1: Download VM

**Option A: VMware Player** (free)
- Download from: https://www.vmware.com/products/workstation-player.html

**Option B: VirtualBox** (free)
- Download from: https://www.virtualbox.org/

### Step 2: Create Ubuntu VM

1. Download Ubuntu 22.04 ISO: https://ubuntu.com/download/desktop
2. Create new VM (4GB RAM, 50GB disk)
3. Install Ubuntu
4. Follow WSL2 build steps inside VM

**Pros:**
- ✅ Clean environment
- ✅ Can snapshot/restore
- ✅ Isolated from host

**Cons:**
- ⏰ Time-consuming setup
- 💾 Large disk usage (50GB+)
- 🐌 Slower than native

---

## Strategy 10: Fix Just the C++ Headers

**Why:** Minimal fix, keep VS2026

**Time:** 30 minutes - 2 hours
**Success Probability:** 40%
**Difficulty:** Hard (experimental)

### Step 1: Find VS2022 Headers on Another Machine

If you have access to a machine with working VS2022:
1. Copy entire include directory
2. Path: `C:\Program Files\Microsoft Visual Studio\2022\...\VC\Tools\MSVC\14.xx\include\`

### Step 2: Place in VS2026 Location

```bash
# Copy to:
J:\Visual Studio\VS Studio\VC\Tools\MSVC\14.50.34357\include\
```

### Step 3: Try Build

```bash
# Open VS2026 Developer Command Prompt
cd "J:\github orca\OrcaSlicer\deps\build-x64"
ninja
```

**Warning:** This is a hack and may cause:
- Version mismatches
- Linker errors
- Runtime issues
- Undefined behavior

**Not recommended** unless desperate.

---

## Priority Recommendation

### 🥇 Do This First: GitHub Actions
- Already set up
- 90% success
- No local changes
- Multi-platform
- See FORK-SETUP-GUIDE.md

### 🥈 Do This Second: WSL2
- 1 hour total
- 85% success
- Proven Linux toolchain
- See Strategy 1 above

### 🥉 Do This Third: VS2022
- 2-3 hours
- 80% success
- Official toolchain
- See Strategy 2 above

### 🔧 Last Resort: Fix VS2026
- 2-3 hours
- 70% success
- Experimental
- See Strategy 3 above

---

## Quick Decision Matrix

| Strategy | Time | Success | Difficulty | Output |
|----------|------|---------|------------|--------|
| **GitHub Actions** | 3 hrs | 90% | Easy | Win/Linux/macOS |
| **WSL2** | 1 hr | 85% | Easy | Linux |
| **VS2022** | 3 hrs | 80% | Medium | Windows |
| **Fix VS2026** | 3 hrs | 70% | Medium | Windows |
| **Docker** | 2 hrs | 80% | Medium | Linux |
| **MinGW** | 2 hrs | 60% | Hard | Windows |
| **VM** | 3 hrs | 85% | Medium | Any |
| **Community** | varies | 90% | Easy | Any |

---

## Parallel Approach (Recommended)

**Do all 3 simultaneously:**

1. **Start now:** GitHub Actions
   - Create fork
   - Push branch
   - Trigger build
   - **Wait 2-3 hours** (do other things while waiting)

2. **While GitHub builds:** Enable WSL2
   - Run PowerShell commands
   - Restart computer (5 minutes)
   - Install deps and build (1 hour)
   - **Have Linux executable** before GitHub finishes

3. **If WSL2 fails:** Install VS2022
   - Download in background
   - Install while doing other things
   - Rebuild when ready

**Result:** Multiple paths to success, maximize probability!

---

## Next Steps

**Right now:**
1. Read BUILD-ENVIRONMENT-ANALYSIS.md (understand problem)
2. Read FORK-SETUP-GUIDE.md (push to GitHub)
3. Read LOCAL-ACTIONS-GUIDE.md (optional: local workflow testing)
4. Choose strategy from this file

**Recommended sequence:**
1. ✅ Fork + push to GitHub (5 min)
2. ✅ Trigger GitHub Actions (2 min)
3. ✅ Enable WSL2 while waiting (1 hour)
4. ✅ Test executables from both builds

---

**Status:** Multiple viable paths identified ✅
**Recommendation:** GitHub Actions + WSL2 (parallel approach)
**Expected Result:** Working executable within 3 hours
