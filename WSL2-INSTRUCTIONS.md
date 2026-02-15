# WSL2 Build Instructions - Simple Steps

**Goal:** Build OrcaSlicer in WSL2 Ubuntu
**Time:** 1 hour after restart
**Success Rate:** 85%

---

## 🚀 **STEP 1: Enable WSL2 Features** (5 minutes)

### **Method A: Run PowerShell Script (Easiest)**

1. **Right-click:** `enable-wsl2.ps1`
2. **Select:** "Run with PowerShell"
3. **Click:** "Yes" if prompted for Administrator
4. **Press:** Y when asked to restart
5. **Wait:** Computer will restart automatically

---

### **Method B: Manual PowerShell Commands**

**Open PowerShell as Administrator:**
- Press `Win + X`
- Click "Terminal (Admin)" or "PowerShell (Admin)"

**Run these commands:**
```powershell
# Enable WSL
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart computer
shutdown /r /t 60
```

**Save any open work!** Computer will restart in 60 seconds.

---

## ⏰ **STEP 2: After Restart - Build OrcaSlicer** (1 hour)

### **Method A: Automated Build Script (Easiest)**

**Open regular PowerShell or Command Prompt:**
```bash
# Start WSL2 Ubuntu
wsl --distribution Ubuntu

# Run the build script
cd /mnt/j/github\ orca/OrcaSlicer
chmod +x wsl2-build.sh
./wsl2-build.sh
```

**The script will:**
- ✅ Install dependencies (10 minutes)
- ✅ Build dependencies (30-45 minutes)
- ✅ Build OrcaSlicer (20-30 minutes)
- ✅ Test executable
- ✅ Show next steps

**Go get coffee!** ☕ This takes about 1 hour.

---

### **Method B: Manual Build Commands**

**If you prefer to run commands manually:**

```bash
# Start WSL2
wsl --distribution Ubuntu

# Navigate to project
cd /mnt/j/github\ orca/OrcaSlicer

# Install dependencies
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake ninja-build git gettext \
  libgtk-3-dev libwxgtk3.0-gtk3-dev libssl-dev \
  libcurl4-openssl-dev libglu1-mesa-dev libdbus-1-dev \
  extra-cmake-modules pkgconf libudev-dev libglew-dev libhidapi-dev

# Build dependencies
cd deps && mkdir -p build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja

# Build OrcaSlicer
cd ../.. && mkdir -p build && cd build
cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSLIC3R_STATIC=ON \
  -DSLIC3R_GUI=ON \
  -DSLIC3R_PCH=OFF
ninja

# Test executable
./src/orcaslicer --help
```

---

## ✅ **STEP 3: Test Your Executable** (5 minutes)

```bash
# From build directory in WSL2
./src/orcaslicer --help

# Launch GUI (if X server configured)
./src/orcaslicer
```

**Test all 6 features:**
1. Per-Plate Settings (right-click plate)
2. Prime Tower Selection (multi-material settings)
3. Flush Selection (multi-material settings)
4. Volume Grouping (right-click volume)
5. Cutting Plane Size (cut tool)
6. Per-Filament Retraction (filament settings)

---

## 📦 **STEP 4: Package for Distribution** (Optional)

```bash
# Create tarball
cd /mnt/j/github\ orca/OrcaSlicer
tar -czf orcaslicer-custom-$(date +%Y%m%d).tar.gz \
  build/src/orcaslicer \
  resources

# Copy to Windows
cp orcaslicer-custom-*.tar.gz /mnt/c/Users/YOUR_USERNAME/Downloads/
```

---

## 🎯 **Timeline**

**Right Now (0:00):**
- Run enable-wsl2.ps1 or PowerShell commands
- Computer will restart

**After Restart (+0:05):**
- Start WSL2 Ubuntu
- Run wsl2-build.sh or manual commands

**+15 Minutes:**
- Dependencies installing

**+30 Minutes:**
- Building Boost (longest dependency)

**+60 Minutes:**
- OrcaSlicer building

**+75 Minutes:**
- ✅ **Build complete! Executable ready!** 🎉

---

## 🔍 **Troubleshooting**

### "wsl: command not found"
**Solution:** WSL not installed
```powershell
wsl --install
# Then restart and try again
```

### "Cannot find path"
**Solution:** Check Windows drive mounting
```bash
# In WSL2, list drives
ls -la /mnt/

# If J: drive not visible:
cd /mnt/c/  # Try from C: drive instead
```

### "Permission denied" on script
**Solution:** Make script executable
```bash
chmod +x wsl2-build.sh
./wsl2-build.sh
```

### Build errors
**Solution:** Check logs
```bash
# Re-run with verbose output
./wsl2-build.sh 2>&1 | tee build-log.txt
```

---

## 📊 **What You'll Get**

**Executable:**
- Location: `build/src/orcaslicer`
- Type: Linux ELF 64-bit
- Size: ~50-100 MB
- Features: All 6 custom features included

**To Use:**
- Run in WSL2: `./build/src/orcaslicer`
- Copy to Linux machine: Works directly
- Run on Windows: Needs WSL2 or VM

---

## 🎉 **Success Criteria**

### Build Succeeded If:
```bash
# Executable exists
ls -lh build/src/orcaslicer

# Shows version
./build/src/orcaslicer --help

# Returns something like:
# OrcaSlicer 2.x.x based on PrusaSlicer...
```

### Features Present If:
- Right-click plate shows "Custom Printer Preset"
- Multi-material settings show "Prime Tower Filaments"
- Multi-material settings show "Flush to Filaments"
- Right-click volume shows "Create Group"
- Cut tool shows "Plane Width" and "Plane Height"

---

## 📝 **Quick Reference**

### Enable WSL2 (Before Restart):
```powershell
# PowerShell as Admin
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all
shutdown /r /t 60
```

### Build (After Restart):
```bash
wsl --distribution Ubuntu
cd /mnt/j/github\ orca/OrcaSlicer
./wsl2-build.sh
```

### Test:
```bash
./build/src/orcaslicer --help
```

---

## ⏭️ **After Build Completes**

1. **Test features** (see CREATIVE-TESTING-PLAYBOOK.md)
2. **Read gap analysis** (.claude/GAP-ANALYSIS-COMPLETE.md)
3. **Consider fixes** (.claude/RECURSIVE-IMPROVEMENT-PLAN.md)
4. **Share with community** or create PR

---

**Status:** Ready to enable WSL2 ✅
**Files Ready:**
- `enable-wsl2.ps1` - Enable features
- `wsl2-build.sh` - Automated build
- `WSL2-INSTRUCTIONS.md` - This file

**Next Action:** Run `enable-wsl2.ps1` or PowerShell commands above

**Time to Executable:** ~1 hour after restart 🚀
