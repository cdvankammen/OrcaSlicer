# Upstream Sync & Code Review Guide

**Purpose:** Stay current with OrcaSlicer/OrcaSlicer while protecting your custom work

---

## When to Sync

**Recommended Frequency:** Weekly or bi-weekly
**Check for Updates:** https://github.com/OrcaSlicer/OrcaSlicer/commits/main

---

## Sync Process with Code Review

### Step 1: Check What's New Upstream

```bash
cd "J:/github orca/my own fork of orca/OrcaSlicer"
git fetch upstream

# See how many commits you're behind
git rev-list --left-right --count origin/main...upstream/main
```

Output will show: `X  Y` where Y = number of new upstream commits

### Step 2: Review Upstream Commits BEFORE Merging

```bash
# List new commits with summaries
git log origin/main..upstream/main --oneline

# See detailed changes
git log origin/main..upstream/main --stat

# View full diff
git diff origin/main...upstream/main
```

### Step 3: Major Code Review Checklist

For each upstream commit, check:

**🔍 What Files Changed?**
```bash
git show COMMIT_HASH --stat
```

**🔍 Does it touch your custom code?**
Check if these files were modified:
- `src/slic3r/GUI/PartPlate.cpp` (per-plate presets)
- `src/slic3r/GUI/PartPlate.hpp` (per-plate presets)
- `src/slic3r/GUI/Plater.cpp` (flush/prime tower)
- `src/libslic3r/Format/bbs_3mf.cpp` (3MF serialization)
- `src/libslic3r/Model.cpp` (object grouping)
- `src/libslic3r/Model.hpp` (object grouping)

**🔍 Potential Conflicts?**
```bash
# Check if upstream changed files you modified
git diff origin/main upstream/main -- src/slic3r/GUI/PartPlate.cpp
git diff origin/main upstream/main -- src/slic3r/GUI/Plater.cpp
```

**🔍 Bug Fixes or Security Issues?**
Look for commits with keywords:
- "fix"
- "crash"
- "security"
- "CVE"
- "vulnerability"

**🔍 API or Structure Changes?**
Look for changes in:
- Class definitions
- Function signatures
- Config options
- File formats

### Step 4: Merge with Review

```bash
# Update your main branch
git checkout main
git merge upstream/main
git push origin main

# Review changes one more time before merging into your work
git log main ^cdv-personal --patch | less

# Merge into your working branch
git checkout cdv-personal
git merge main
```

If merge conflicts occur:
```bash
# See which files conflict
git status

# For each conflict:
# 1. Edit the file
# 2. Look for <<<<<<< HEAD markers
# 3. Choose or combine changes
# 4. Remove conflict markers
# 5. git add <file>

git commit -m "Merge upstream main with conflict resolution"
```

### Step 5: Post-Merge Testing

After merging upstream changes:

1. **Build Test:**
   ```bash
   # Trigger GitHub Actions build
   git push origin cdv-personal
   ```

2. **Feature Test Checklist:**
   - [ ] Per-plate printer presets work
   - [ ] Per-plate filament presets work
   - [ ] Prime tower material selection works
   - [ ] Support/infill flush selection works
   - [ ] Object grouping works
   - [ ] Cutting plane resize works

3. **Regression Check:**
   - [ ] Project files load correctly
   - [ ] 3MF serialization works
   - [ ] No new crashes
   - [ ] UI still responsive

---

## Example: Last Sync (2026-02-15)

We merged 5 commits from upstream:

1. **bf59fe458f** - Fix EGL/GLX mismatch (Linux 3D preview)
   - Files: `src/slic3r/GUI/OpenGLManager.cpp`
   - Impact: None on custom features
   - Risk: Low

2. **055f24ca7a** - Happy Hare support (Moonraker)
   - Files: `src/slic3r/Utils/MoonrakerPrinterAgent.cpp/hpp`
   - Impact: None on custom features
   - Risk: Low

3. **06cee7ffe7** - Profile version bump
   - Files: `resources/profiles/*.json` (all profiles)
   - Impact: Profile version changed to 02.03.02.40
   - Risk: Low (version metadata only)

4. **5ec4874b33** - VFA tower repair
   - Files: `resources/calib/vfa/`, `src/slic3r/Utils/CalibUtils.cpp`
   - Impact: None on custom features
   - Risk: Low

5. **783f9926e3** - Revert Mac runner
   - Files: `.github/workflows/` (CI/CD only)
   - Impact: None on code
   - Risk: None

**Result:** All 5 commits were safe to merge, no conflicts with custom features.

---

## Red Flags to Watch For

### 🚨 High Risk Changes:

**If upstream modifies:**
- PartPlate class structure
- 3MF file format (bbs_3mf.cpp)
- Model/ModelObject classes
- Config option naming or types
- Print pipeline flow

**Action:** Extra careful review, extensive testing after merge

### ⚠️ Medium Risk Changes:

**If upstream modifies:**
- GUI code near your changes
- Serialization code
- Build system (CMake files)

**Action:** Thorough testing, check for conflicts

### ✅ Low Risk Changes:

**Safe merges:**
- Profile updates
- Translation files
- Documentation
- Bug fixes in unrelated code
- CI/CD workflow changes

---

## Conflict Resolution Strategy

When conflicts occur:

### 1. Understand Both Changes
```bash
# See your version
git show :2:path/to/file.cpp

# See upstream version
git show :3:path/to/file.cpp
```

### 2. Resolution Priority

**Preserve your features FIRST:**
- Keep your per-plate preset code
- Keep your custom config options
- Keep your UI additions

**Accept upstream changes for:**
- Bug fixes
- Security fixes
- Performance improvements
- New unrelated features

### 3. When in Doubt
- Keep both changes if possible (non-overlapping)
- Test thoroughly after resolution
- Document why you chose specific resolution

---

## Automation (Optional)

### Weekly Sync Script:

```bash
#!/bin/bash
# weekly-sync.sh

cd "J:/github orca/my own fork of orca/OrcaSlicer"

echo "Fetching upstream..."
git fetch upstream

echo ""
echo "New upstream commits:"
git log origin/main..upstream/main --oneline

echo ""
echo "Files changed:"
git diff --stat origin/main upstream/main

echo ""
read -p "Proceed with merge? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    git checkout main
    git merge upstream/main
    git push origin main

    echo ""
    echo "Merge into cdv-personal? (review first!)"
    read -p "Proceed? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout cdv-personal
        git merge main
        git push origin cdv-personal
        echo "✅ Sync complete!"
    fi
fi
```

---

## Summary

**Sync Frequency:** Weekly
**Review Process:** Always review upstream changes before merging
**Test After Merge:** Build + feature testing
**Conflict Resolution:** Preserve your features, accept bug fixes

**Your code is protected** - you only merge when YOU decide to merge, after reviewing the changes.

**Staying current is important** - but never at the cost of breaking your custom features!
