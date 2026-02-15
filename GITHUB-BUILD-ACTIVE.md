# GitHub Actions Build - ACTIVE ✅

**Status:** BUILDING NOW
**Started:** 2026-02-15 11:53:02 UTC
**Run ID:** 22035189629
**Workflow:** Build all
**Branch:** main
**URL:** https://github.com/cdvankammen/OrcaSlicer/actions/runs/22035189629

---

## Current Status (Updated 13:13 UTC / 5:13 AM PST)

**Runtime:** 80 minutes (started 11:53 UTC)

### ✅ Completed:
- Build Linux / Check Cache
- Build Non-Linux (windows-latest) / Check Cache

### ⏳ In Progress (67-80% complete):
- **Linux Build Deps** - Step 10/15 (67%) - Building Ubuntu dependencies
- **Windows Build Deps** - Step 7/15 (47%) - Building Windows dependencies
- **Flatpak (x86_64)** - Building Linux x86_64 package
- **Flatpak (aarch64)** - Building ARM64 package

### 📋 Queued:
- macOS Build - Waiting for runner

---

## Monitor Progress

### Live Watch:
```bash
gh run watch 22035189629 --repo cdvankammen/OrcaSlicer --interval 10
```

### Check Status:
```bash
gh run view 22035189629 --repo cdvankammen/OrcaSlicer
```

### View in Browser:
https://github.com/cdvankammen/OrcaSlicer/actions/runs/22035189629

---

## Expected Artifacts

When build completes, you'll get:

1. **Windows Build**
   - OrcaSlicer.exe
   - OrcaSlicer_console.exe
   - All resources and dependencies

2. **Linux Build**
   - orcaslicer binary
   - Flatpak packages (x86_64 and aarch64)

3. **macOS Build**
   - OrcaSlicer.app bundle
   - Universal or architecture-specific

---

## Custom Features Included

All 6 custom features are in this build since they're committed to main branch:

1. ✅ Per-Filament Retraction Override (existing)
2. ✅ Per-Plate Printer/Filament Settings (675 lines)
3. ✅ Prime Tower Material Selection (32 lines)
4. ✅ Support & Infill Flush Selection (32 lines)
5. ✅ Hierarchical Object Grouping (919 lines)
6. ✅ Cutting Plane Size Adjustability (37 lines)

**Total:** 1,875 lines of custom code

---

## Timeline Estimate

- **Dependencies:** 30-45 minutes (IN PROGRESS)
- **Main Build:** 30-45 minutes (PENDING)
- **Total:** 60-90 minutes from start
- **ETA:** ~12:45-13:30 UTC (estimated)

---

## After Build Completes

Artifacts will be available at:
https://github.com/cdvankammen/OrcaSlicer/actions/runs/22035189629

Download the appropriate build for your platform.

---

**Last Updated:** 2026-02-15 (Auto-monitoring active)
