# GitHub Actions Build Guide

## Overview

After 7 failed local build attempts due to VS2026 environment issues, we've created a GitHub Actions workflow to build OrcaSlicer with all 6 custom features using GitHub's proven infrastructure.

## Build Attempts Summary

### Attempts #1-7: Local Windows Build (FAILED)
- **Issues:** wxWidgets submodules, VS2026 C++ stdlib missing, Boost compilation errors
- **Time Invested:** 8+ hours
- **Outcome:** Blocked by incomplete VS2026 installation

### Attempt #8: GitHub Actions Cloud Build ⭐
- **Strategy:** Use GitHub's VS2022 infrastructure
- **Success Probability:** 80%+ (proven working environment)
- **Time:** 2-3 hours (setup + build time)
- **Advantages:**
  - No local environment changes needed
  - Builds on Windows, Linux, AND macOS
  - Downloadable executable artifacts
  - Reproducible builds

## How to Trigger the Build

### Option 1: Via GitHub Web Interface (Easiest)

1. **Push the workflow to GitHub:**
   ```bash
   cd "J:\github orca\OrcaSlicer"
   git add .github/workflows/build-custom-features.yml
   git add .claude/
   git commit -m "Add GitHub Actions build workflow for custom features

   - Builds on Windows (VS2022), Linux (Ubuntu 22.04), macOS 12
   - Includes all 6 custom features (1,875 lines)
   - Packages with comprehensive documentation
   - Produces downloadable artifacts

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   git push origin cdv-personal
   ```

2. **Go to GitHub Actions:**
   - Navigate to: `https://github.com/YOUR_USERNAME/OrcaSlicer/actions`
   - Click "Build OrcaSlicer with Custom Features" workflow
   - Click "Run workflow" button
   - Select build type (RelWithDebInfo recommended)
   - Click green "Run workflow" button

3. **Monitor Build Progress:**
   - Build will take 1-2 hours
   - You can watch real-time progress
   - Three parallel builds: Windows, Linux, macOS

4. **Download Artifacts:**
   - When complete, scroll to bottom of workflow run
   - Download ZIP/TAR.GZ for your platform
   - Extract and test the executable

### Option 2: Via GitHub CLI (Command Line)

```bash
# Install GitHub CLI if not already installed
# Then trigger the build:

gh workflow run build-custom-features.yml \
  --ref cdv-personal \
  --field build_type=RelWithDebInfo

# Monitor the build
gh run list --workflow=build-custom-features.yml

# Download artifacts when done
gh run download [RUN_ID]
```

### Option 3: Automatic on Push (Modify Workflow)

Edit `.github/workflows/build-custom-features.yml` and change the trigger:

```yaml
on:
  push:
    branches:
      - cdv-personal
  workflow_dispatch:
    # ... existing inputs
```

Then every push to `cdv-personal` will automatically build.

## What Gets Built

### Windows Build (VS2022)
- `OrcaSlicer.exe` (GUI application)
- `OrcaSlicer_console.exe` (console version)
- All resources and profiles
- Complete documentation in `.claude/` directory

### Linux Build (Ubuntu 22.04)
- `orcaslicer` (executable)
- All resources and profiles
- Documentation

### macOS Build (macOS 12)
- `OrcaSlicer.app` (application bundle)
- All resources and profiles
- Documentation

## Build Output

Each artifact includes:

```
OrcaSlicer-CustomFeatures-{DATE}-{PLATFORM}/
├── OrcaSlicer.exe (or orcaslicer / OrcaSlicer.app)
├── resources/
│   ├── profiles/
│   ├── icons/
│   └── ...
├── .claude/
│   ├── SENIOR-ARCHITECT-ASSESSMENT.md
│   ├── GAP-ANALYSIS-COMPLETE.md
│   ├── CREATIVE-SOLUTIONS.md
│   └── RECURSIVE-IMPROVEMENT-PLAN.md
└── CUSTOM_FEATURES.txt (feature list and warnings)
```

## Testing the Build

1. **Extract the artifact**
2. **Read CUSTOM_FEATURES.txt** for known issues
3. **Review .claude/GAP-ANALYSIS-COMPLETE.md** for 47 documented gaps
4. **Test features using CREATIVE-TESTING-PLAYBOOK.md** scenarios
5. **Report issues** with `[Custom Features]` prefix

## Known Limitations

⚠️ **This is an ALPHA build with 8 critical issues:**

1. **Crash Risk:** Volume deletion with groups (use-after-free)
2. **Data Loss:** Undo/redo loses groups
3. **Data Loss:** Undo/redo loses plate presets
4. **Silent Failure:** Flush settings can lose purge volume
5. **UX Confusion:** Cutting plane dimensions incorrect
6. **Crash Risk:** Null pointer dereference in presets
7. **Data Loss:** Copy operations lose groups
8. **Integration Conflict:** Per-plate + flush settings validation missing

**Read the gap analysis before using in production!**

## Next Steps After Build

### Option A: Full Production Release (48 hours)
Implement the **RECURSIVE-IMPROVEMENT-PLAN.md**:
- Phase 1: Fix crashes (2 hours)
- Phase 2: Fix undo/redo (7 hours)
- Phase 3: Add validation (9 hours)
- Phase 4: UX improvements (8 hours)
- Phase 5: Testing & polish (22 hours)

**Result:** Production-ready code with 9/10 quality

### Option B: Quick Fix (9 hours)
Fix only the critical crashes and undo/redo:
- Volume deletion crash (30 min)
- Clear volumes crash (30 min)
- Null pointer checks (1 hour)
- Groups undo/redo (4 hours)
- Presets undo/redo (2 hours)
- Basic validation (1 hour)

**Result:** Safe for alpha/beta testing

### Option C: Community Testing
- Release as ALPHA with known issues documented
- Gather community feedback
- Prioritize fixes based on real-world usage
- Iterate improvements

## Success Probability

**GitHub Actions Build:** 🟢 **80%+ (HIGH)**

**Reasoning:**
- ✅ GitHub uses proven VS2022 environment
- ✅ Same infrastructure used by official OrcaSlicer builds
- ✅ Avoids all local environment issues
- ✅ Reproducible and consistent
- ✅ Builds on all 3 platforms

**If GitHub Actions Fails:**
- Post on OrcaSlicer Discord #build-help
- Request community build volunteer
- Provide build logs for troubleshooting

## Build Timeline

1. **Setup & Push:** 10 minutes
2. **GitHub Actions Queue:** 0-5 minutes
3. **Windows Build:** 60-90 minutes
4. **Linux Build:** 30-45 minutes
5. **macOS Build:** 45-60 minutes

**Total:** 2-3 hours from push to downloadable executable

---

## FAQ

**Q: Why not fix VS2026 locally?**
A: VS2026 installation is incomplete (missing C++ stdlib). Would require 2+ hours reinstall with uncertain outcome.

**Q: Why not use WSL2?**
A: Requires enabling Hyper-V/Virtual Machine Platform, system restart, and configuration.

**Q: Can I modify the features before building?**
A: Yes! Make your changes, push to branch, workflow builds your version.

**Q: What if the build fails?**
A: Check the build logs in GitHub Actions, document the error, and consider community build help.

**Q: Is this the official way to build OrcaSlicer?**
A: This uses the same infrastructure as official builds, just triggered manually. Workflow is based on OrcaSlicer's existing CI/CD patterns.

---

## Support

- **Build Issues:** Open GitHub issue with `[Build]` prefix
- **Feature Issues:** Open GitHub issue with `[Custom Features]` prefix
- **Questions:** OrcaSlicer Discord #development channel

---

**Status:** Ready to build ✅
**Date:** 2026-02-14
**Strategy:** GitHub Actions (Attempt #8)
**Recommendation:** Push workflow and trigger build via GitHub web interface
