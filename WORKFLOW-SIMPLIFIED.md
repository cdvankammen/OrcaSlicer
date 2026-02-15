# Simplified Workflow - Your Fork Only

**Your Fork:** cdvankammen/OrcaSlicer
**Working Directory:** J:\github orca\my own fork of orca\OrcaSlicer

---

## Branch Structure (Simplified)

### `main`
- Mirrors upstream OrcaSlicer/OrcaSlicer:main
- Always kept in sync with parent project
- **Purpose:** Track upstream changes only
- **Never commit custom work here**

### `cdv-personal`
- **YOUR working branch** - all custom features here
- All 1,875 lines of custom code
- This is where you develop and commit
- **This is your primary branch**

---

## Daily Workflow

### Working on Your Features:
```bash
cd "J:/github orca/my own fork of orca/OrcaSlicer"
git checkout cdv-personal
git pull origin cdv-personal

# ... make changes ...

git add .
git commit -m "Description of changes"
git push origin cdv-personal
```

### Syncing with Upstream OrcaSlicer (Weekly):
```bash
# Step 1: Update main with upstream
git checkout main
git fetch upstream
git merge upstream/main
git push origin main

# Step 2: Merge upstream changes into YOUR branch
git checkout cdv-personal
git merge main
# ... resolve any conflicts if they occur ...
git push origin cdv-personal
```

---

## Code Review When Syncing Upstream

When you sync with upstream (merge main into cdv-personal), always review:

### 1. Check What Changed Upstream:
```bash
git log main ^cdv-personal --oneline
```

### 2. Review Commits Before Merging:
```bash
# See detailed changes
git log upstream/main ^origin/main --patch

# Or view in GitHub
# https://github.com/OrcaSlicer/OrcaSlicer/compare/YOUR_LAST_SYNC...main
```

### 3. After Merging, Test:
```bash
git checkout cdv-personal
git merge main
# Build and test locally or trigger GitHub Actions
```

### 4. Look for Conflicts or Issues:
- Check if upstream modified files you changed
- Test your custom features still work
- Review for potential bugs introduced

---

## Building

### GitHub Actions (Recommended):
Your fork builds automatically on push, or manual trigger:
```bash
gh workflow run build-custom-features.yml --repo cdvankammen/OrcaSlicer --ref cdv-personal
```

### Local Building:
Current blockers documented in LOCAL-BUILD-FINAL-STATUS.md
- VS2026: Missing stdlib
- Docker: Daemon issues
- WSL2: Not enabled
- MinGW: Path with space issue

**Recommendation:** Use GitHub Actions until local environment fixed

---

## Important Notes

### You Work ONLY in Your Fork:
- ✅ Push to: `origin` (cdvankammen/OrcaSlicer)
- ✅ Branch: `cdv-personal`
- ❌ NEVER push to upstream (OrcaSlicer/OrcaSlicer)

### Keep Your Fork Updated:
- Sync `main` with `upstream/main` weekly
- Merge `main` into `cdv-personal` after reviewing changes
- This keeps you current with OrcaSlicer development

### All Custom Work on cdv-personal:
- Per-Filament Retraction Override
- Per-Plate Printer/Filament Settings
- Prime Tower Material Selection
- Support & Infill Flush Selection
- Hierarchical Object Grouping
- Cutting Plane Size Adjustability

---

## Summary

**Where You Work:** cdvankammen/OrcaSlicer (your fork)
**Your Branch:** cdv-personal
**Upstream Sync:** main ← upstream/main, then cdv-personal ← main
**Building:** GitHub Actions (local not working yet)

**Nothing was lost!** All your code is safe on cdv-personal.
