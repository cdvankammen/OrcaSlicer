# OrcaSlicer Build Instructions

## ✅ What's Ready:
- CMake 3.31.5 installed and configured
- Build directories cleaned
- Build scripts prepared
- Source packages cached (from previous attempts)

## 📋 Next Steps:

### 1. Install VS 2022 Community (if not already installed)
- Go to: https://visualstudio.microsoft.com/downloads/
- Download "Community 2022" (FREE)
- During installation:
  - ✅ Select "Desktop development with C++"
  - 📁 Change install location to: `J:\visualstudio\vs2022`
- Takes ~20 minutes

### 2. Run the Build
After VS 2022 is installed, double-click:
```
build_with_vs2022.bat
```

This will:
- Verify VS 2022 is installed
- Build all dependencies
- Build OrcaSlicer
- Open the solution in Visual Studio when done

### 3. Monitor Progress (Optional)
In PowerShell, run:
```powershell
powershell -ExecutionPolicy Bypass -File monitor_build.ps1
```

This shows real-time build progress.

## ⏱️ Expected Build Time:
- Dependencies: 20-40 minutes
- OrcaSlicer: 10-20 minutes
- **Total: 30-60 minutes**

## 📂 Final Output:
- Solution file: `build\OrcaSlicer.sln`
- Executable: `build\OrcaSlicer\Release\orca-slicer.exe`

## ❓ Troubleshooting:
- If build fails, check: `build_progress.log`
- All dependency sources cached in: `deps\DL_CACHE\`
- Build output in: `deps\build\` and `build\`

---
**Built with Claude Code** 🤖
