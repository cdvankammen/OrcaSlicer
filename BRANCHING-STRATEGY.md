# Branching Strategy for cdvankammen/OrcaSlicer

## Branch Structure

### Production Branches

**`main`** - Stable production branch
- Always buildable and tested
- Synced with upstream OrcaSlicer/OrcaSlicer:main
- Tagged releases for versions
- Protected: requires review before merges
- **Purpose:** Stable builds for end users

### Development Branches

**`develop`** - Active development branch (TO CREATE)
- Integration branch for features
- All custom features developed here first
- Regular testing before merging to main
- **Purpose:** Beta testing and feature integration

**`staging`** - Pre-production testing (OPTIONAL)
- Final testing before production release
- Mirrors production environment
- **Purpose:** Final QA before main merge

### Feature Branches

**`feature/<feature-name>`** - Individual feature development
- Created from `develop`
- Merged back to `develop` when complete
- Deleted after merge
- **Current:** `cdv-personal` (to be renamed/reorganized)

---

## Workflow

### Regular Development Cycle

```
upstream/main → main → develop → feature/xxx → develop → main → release tag
```

1. **Sync with upstream** (weekly or as needed):
   ```bash
   git checkout main
   git fetch upstream
   git merge upstream/main
   git push origin main
   ```

2. **Start new feature**:
   ```bash
   git checkout develop
   git checkout -b feature/new-feature-name
   # ... work on feature ...
   git push origin feature/new-feature-name
   ```

3. **Merge feature to develop**:
   ```bash
   git checkout develop
   git merge feature/new-feature-name
   git push origin develop
   ```

4. **Release to production**:
   ```bash
   git checkout main
   git merge develop
   git tag -a v1.0.0-custom -m "Custom features release v1.0.0"
   git push origin main --tags
   ```

---

## Current Situation

**Current branches:**
- `main` - 5 commits behind upstream, 3 commits ahead (mixed state)
- `cdv-personal` - Has all custom features (1,875 lines)

**Recommended Actions:**

1. **Sync main with upstream** (get those 5 commits)
2. **Create develop branch** from current cdv-personal
3. **Reorganize features** into proper feature branches
4. **Protect main branch** on GitHub

---

## GitHub Actions Strategy

### When to Trigger Builds

✅ **DO trigger builds:**
- Merging to `main` (production release)
- Weekly on `develop` (integration testing)
- Pull requests to `main` or `develop`
- Manual testing of significant features

❌ **DON'T trigger builds:**
- Every commit on feature branches
- Experimental/WIP commits
- Documentation-only changes
- Multiple builds for same code

### Build Configuration

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:  # Manual trigger only when needed
  schedule:
    - cron: '0 0 * * 0'  # Weekly build on Sunday (optional)
```

**Current usage:** 1 build triggered (totally reasonable!)
**Monthly limit:** 2,000 minutes (you've used ~95 minutes)
**Remaining:** 1,905 minutes (~20 more full builds available)

---

## Release Strategy

### Version Naming

**Stable releases:** `v1.0.0-custom`, `v2.0.0-custom`
**Beta releases:** `v1.0.0-beta-custom`, `v2.0.0-rc-custom`
**Nightly builds:** `nightly-YYYYMMDD-custom`

### Release Process

1. Merge all features to `develop`
2. Test thoroughly on `develop`
3. Create release branch: `release/v1.0.0-custom`
4. Final testing and bug fixes on release branch
5. Merge to `main` and tag
6. Trigger GitHub Actions build for release
7. Publish artifacts as GitHub Release

---

## Syncing with Upstream OrcaSlicer

### Regular Sync (Weekly/Bi-weekly)

```bash
# Update main with upstream changes
git checkout main
git fetch upstream
git merge upstream/main
git push origin main

# Merge main into develop
git checkout develop
git merge main
git push origin develop

# Update feature branches (if needed)
git checkout feature/your-feature
git merge develop
git push origin feature/your-feature
```

### Handling Conflicts

When upstream changes conflict with custom features:
1. Resolve conflicts in `develop` first
2. Test that custom features still work
3. Update feature branches from `develop`
4. Document any changes needed

---

## Protection Rules (Recommended GitHub Settings)

### Main Branch Protection:
- ✅ Require pull request reviews
- ✅ Require status checks (build must pass)
- ✅ Prevent force push
- ✅ Prevent deletion

### Develop Branch Protection:
- ✅ Require status checks
- ❌ Allow force push (for development flexibility)
- ✅ Prevent deletion

---

## Summary

**Current Setup:** Basic (main + cdv-personal)
**Recommended:** `main` (stable) ← `develop` (testing) ← `feature/*` (development)

**Next Steps:**
1. Sync `main` with upstream (get 5 missing commits)
2. Create `develop` branch from `cdv-personal`
3. Rename `cdv-personal` to descriptive feature branches
4. Set up branch protection on GitHub
5. Update GitHub Actions to build on main/develop only

**Build Budget:** 1,905 minutes remaining (95% available)
**GitHub Actions:** Responsible usage, no abuse concerns
