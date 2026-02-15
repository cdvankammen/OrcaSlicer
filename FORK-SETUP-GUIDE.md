# Fork Setup Guide - Convert Clone to Fork

**Problem:** You cloned the official OrcaSlicer repository, but need your own fork to push changes.

**Solution:** Create a fork on GitHub and update your local repository to point to it.

---

## Quick Start (3 Steps)

### Step 1: Create Fork on GitHub
1. Go to: https://github.com/SoftFever/OrcaSlicer
2. Click the "Fork" button (top-right corner)
3. Wait for fork to complete (30-60 seconds)
4. Note your fork URL: `https://github.com/YOUR_USERNAME/OrcaSlicer`

### Step 2: Update Local Remote
```bash
cd "J:\github orca\OrcaSlicer"

# Add your fork as a remote
git remote add myfork https://github.com/YOUR_USERNAME/OrcaSlicer.git

# Or rename origin to upstream and add your fork as origin
git remote rename origin upstream
git remote add origin https://github.com/YOUR_USERNAME/OrcaSlicer.git
```

### Step 3: Push Your Branch
```bash
# Push to your fork
git push myfork cdv-personal

# Or if you renamed remotes:
git push origin cdv-personal
```

---

## Detailed Instructions

### What Happened

You currently have:
```bash
origin → https://github.com/OrcaSlicer/OrcaSlicer.git (official repo)
```

You need:
```bash
origin → https://github.com/YOUR_USERNAME/OrcaSlicer.git (your fork)
upstream → https://github.com/OrcaSlicer/OrcaSlicer.git (official repo)
```

---

### Method 1: Add Fork as New Remote (Recommended)

**Step 1: Create fork on GitHub**
- Go to https://github.com/SoftFever/OrcaSlicer
- Click "Fork" button
- Wait for completion

**Step 2: Add your fork**
```bash
# Add your fork (replace YOUR_USERNAME)
git remote add myfork https://github.com/YOUR_USERNAME/OrcaSlicer.git

# Verify
git remote -v
```

You should see:
```
origin    https://github.com/OrcaSlicer/OrcaSlicer.git (fetch)
origin    https://github.com/OrcaSlicer/OrcaSlicer.git (push)
myfork    https://github.com/YOUR_USERNAME/OrcaSlicer.git (fetch)
myfork    https://github.com/YOUR_USERNAME/OrcaSlicer.git (push)
```

**Step 3: Push to your fork**
```bash
git push myfork cdv-personal
```

**Step 4: Set upstream tracking**
```bash
git branch --set-upstream-to=myfork/cdv-personal cdv-personal
```

---

### Method 2: Rename Origin (Clean Setup)

**Step 1: Create fork on GitHub** (same as Method 1)

**Step 2: Rename remotes**
```bash
# Rename official repo to "upstream"
git remote rename origin upstream

# Add your fork as "origin"
git remote add origin https://github.com/YOUR_USERNAME/OrcaSlicer.git

# Verify
git remote -v
```

You should see:
```
upstream  https://github.com/OrcaSlicer/OrcaSlicer.git (fetch)
upstream  https://github.com/OrcaSlicer/OrcaSlicer.git (push)
origin    https://github.com/YOUR_USERNAME/OrcaSlicer.git (fetch)
origin    https://github.com/YOUR_USERNAME/OrcaSlicer.git (push)
```

**Step 3: Push to your fork**
```bash
git push origin cdv-personal
```

**Step 4: Set upstream tracking**
```bash
git branch --set-upstream-to=origin/cdv-personal cdv-personal
```

---

## After Push: Trigger GitHub Actions

### Via Web UI (Easiest)
1. Go to: `https://github.com/YOUR_USERNAME/OrcaSlicer/actions`
2. Click "Build OrcaSlicer with Custom Features"
3. Click "Run workflow" dropdown
4. Select branch: `cdv-personal`
5. Select build type: `RelWithDebInfo`
6. Click green "Run workflow" button
7. Watch progress (2-3 hours)
8. Download artifacts when complete

### Via GitHub CLI
```bash
# Install GitHub CLI if needed
# Then:
gh workflow run build-custom-features.yml \
  --repo YOUR_USERNAME/OrcaSlicer \
  --ref cdv-personal \
  --field build_type=RelWithDebInfo

# Monitor progress
gh run list --repo YOUR_USERNAME/OrcaSlicer --workflow=build-custom-features.yml

# Download when complete
gh run download --repo YOUR_USERNAME/OrcaSlicer [RUN_ID]
```

---

## Keeping Your Fork Updated

### Sync with Official OrcaSlicer
```bash
# Fetch latest from official repo
git fetch upstream

# Update your main branch
git checkout main
git merge upstream/main

# Push to your fork
git push origin main
```

### Update Your Feature Branch
```bash
# Switch to your branch
git checkout cdv-personal

# Merge latest main
git merge main

# Or rebase (cleaner history)
git rebase main

# Push to your fork
git push origin cdv-personal --force-with-lease
```

---

## Troubleshooting

### "Permission denied" when pushing
**Cause:** Still pointing to official repo or wrong credentials

**Fix:**
```bash
# Check remotes
git remote -v

# If wrong, update:
git remote set-url myfork https://github.com/YOUR_USERNAME/OrcaSlicer.git
git remote set-url origin https://github.com/YOUR_USERNAME/OrcaSlicer.git
```

### "Repository not found"
**Cause:** Fork doesn't exist yet or wrong username

**Fix:**
1. Verify fork exists: Go to `https://github.com/YOUR_USERNAME/OrcaSlicer`
2. Check username is correct
3. Create fork if missing (GitHub website, click "Fork")

### Authentication issues
**Cause:** Need GitHub credentials

**Fix (HTTPS with token):**
```bash
# Use personal access token
git remote set-url myfork https://YOUR_TOKEN@github.com/YOUR_USERNAME/OrcaSlicer.git
```

**Fix (SSH):**
```bash
# Use SSH URL instead
git remote set-url myfork git@github.com:YOUR_USERNAME/OrcaSlicer.git
```

---

## Alternative: Manual Fork Creation

If automated fork doesn't work:

1. **Create empty repository on GitHub**
   - Go to: https://github.com/new
   - Name: `OrcaSlicer`
   - Description: "Fork of OrcaSlicer with custom features"
   - Public or Private
   - DO NOT initialize (no README, .gitignore, license)
   - Click "Create repository"

2. **Push all branches**
   ```bash
   git remote add myfork https://github.com/YOUR_USERNAME/OrcaSlicer.git
   git push myfork --all
   git push myfork --tags
   ```

3. **Set fork relationship** (optional, for PR)
   - Go to your repository settings on GitHub
   - This is mainly for UI purposes

---

## Verify Setup

### Check Remotes
```bash
git remote -v
```

**Good (Method 1):**
```
origin    https://github.com/OrcaSlicer/OrcaSlicer.git
myfork    https://github.com/YOUR_USERNAME/OrcaSlicer.git
```

**Good (Method 2):**
```
upstream  https://github.com/OrcaSlicer/OrcaSlicer.git
origin    https://github.com/YOUR_USERNAME/OrcaSlicer.git
```

### Check Branch Tracking
```bash
git branch -vv
```

**Good:**
```
* cdv-personal 36eb639d [myfork/cdv-personal] Add 6 custom features + GitHub Actions
```

Or:
```
* cdv-personal 36eb639d [origin/cdv-personal] Add 6 custom features + GitHub Actions
```

### Test Push
```bash
git push myfork cdv-personal --dry-run
# Or:
git push origin cdv-personal --dry-run
```

**Good:** Shows what would be pushed, no errors

---

## Quick Reference

### Common Commands
```bash
# Check current setup
git remote -v
git branch -vv

# Add your fork
git remote add myfork https://github.com/YOUR_USERNAME/OrcaSlicer.git

# Push to fork
git push myfork cdv-personal

# Set tracking
git branch --set-upstream-to=myfork/cdv-personal cdv-personal

# Future pushes
git push  # Uses tracked remote automatically
```

### Update from Upstream
```bash
# Fetch latest
git fetch upstream

# Merge into your branch
git checkout cdv-personal
git merge upstream/main

# Push to your fork
git push myfork cdv-personal
```

---

## Next Steps

After successful push:

1. ✅ **Trigger GitHub Actions** (see above)
2. ✅ **Try local GitHub Actions** (see LOCAL-ACTIONS-GUIDE.md)
3. ✅ **Fix local build** (see ADDITIONAL-BUILD-STRATEGIES.md)

---

## Need Your GitHub Username

**I need your GitHub username to give you exact commands.**

Please provide:
- **GitHub username:** ???

Then I can run the exact commands for you!

---

**Status:** Ready for fork creation ✅
**Time:** 5 minutes to complete
**Required:** GitHub account + internet
