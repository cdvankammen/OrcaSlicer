# Local GitHub Actions Guide - Run Workflows Without GitHub

**Goal:** Run the GitHub Actions workflow on your local machine using `act`

**Why:** Test workflows before pushing, build locally without GitHub, faster iteration

---

## What is `act`?

`act` is a tool that runs GitHub Actions workflows locally using Docker containers.

**Pros:**
- ✅ Test workflows before pushing to GitHub
- ✅ Build locally without waiting for GitHub
- ✅ Same environment as GitHub Actions
- ✅ Free and open source

**Cons:**
- ⏰ Requires Docker installation (20 minutes)
- 💾 Large Docker images (~10GB for full environment)
- 🐛 Some GitHub Actions features may not work perfectly
- 💻 Requires good internet for first-time image pull

---

## Quick Start

### Prerequisites
1. **Docker Desktop** - Required for `act` to work
2. **act CLI** - The GitHub Actions runner
3. **Workflow file** - Already created (`.github/workflows/build-custom-features.yml`)

---

## Installation

### Step 1: Install Docker Desktop

**Download:**
- Go to: https://www.docker.com/products/docker-desktop/
- Download Docker Desktop for Windows
- Run installer

**After Install:**
```bash
# Verify Docker is running
docker --version
docker ps
```

**Expected:** `Docker version 24.x.x` or similar

**Time:** 20-30 minutes (download + install + restart)

---

### Step 2: Install `act`

#### Method A: Chocolatey (Easiest)
```bash
# Install Chocolatey if not already installed
# See: https://chocolatey.org/install

# Install act
choco install act-cli

# Verify
act --version
```

#### Method B: Scoop
```bash
scoop install act
```

#### Method C: Manual Download
1. Go to: https://github.com/nektos/act/releases
2. Download `act_Windows_x86_64.zip`
3. Extract to a folder (e.g., `C:\tools\act\`)
4. Add to PATH:
   ```powershell
   $env:Path += ";C:\tools\act\"
   ```

**Verify:**
```bash
act --version
```

**Expected:** `act version 0.2.x` or similar

---

## Running the Workflow

### Step 1: List Available Workflows
```bash
cd "J:\github orca\OrcaSlicer"

# See what workflows are available
act -l
```

**Expected Output:**
```
Stage  Job ID                       Job name                     Workflow name                        Workflow file
0      build-windows                Build Windows (Custom Features)  Build OrcaSlicer with Custom Features  build-custom-features.yml
0      build-linux                  Build Linux (Custom Features)    Build OrcaSlicer with Custom Features  build-custom-features.yml
0      build-macos                  Build macOS (Custom Features)    Build OrcaSlicer with Custom Features  build-custom-features.yml
```

---

### Step 2: Run Specific Job

#### Option A: Run Windows Build
```bash
act workflow_dispatch \
  --job build-windows \
  --input build_type=RelWithDebInfo
```

#### Option B: Run Linux Build (Faster, Recommended)
```bash
act workflow_dispatch \
  --job build-linux \
  --input build_type=RelWithDebInfo
```

#### Option C: Run All Jobs (Parallel)
```bash
act workflow_dispatch \
  --input build_type=RelWithDebInfo
```

---

### Step 3: Monitor Progress

`act` will:
1. Pull Docker image (first time only, ~10GB)
2. Start container
3. Run workflow steps
4. Show output in terminal

**Time:**
- First run: 2-3 hours (image pull + build)
- Subsequent runs: 1-2 hours (build only)

---

## Configuration

### Create `.actrc` File

```bash
# Create config file
cat > .actrc << 'EOF'
# Use GitHub's large runner image
-P ubuntu-22.04=ghcr.io/catthehacker/ubuntu:act-22.04
-P windows-2022=ghcr.io/catthehacker/windows:2022

# Use secrets from file
--secret-file .secrets

# Bind repository as workspace
--bind

# Verbose output
--verbose
EOF
```

### Create `.secrets` File (Optional)

If your workflow needs secrets:

```bash
cat > .secrets << 'EOF'
GITHUB_TOKEN=your_token_here
EOF
```

**Note:** Our workflow doesn't need secrets for building.

---

## Running with Docker Compose (Alternative)

### Create `docker-compose.yml`

```yaml
version: '3.8'

services:
  build-orcaslicer:
    image: ghcr.io/catthehacker/ubuntu:act-22.04
    volumes:
      - .:/workspace
    working_dir: /workspace
    command: |
      bash -c "
        apt-get update &&
        apt-get install -y \
          build-essential cmake ninja-build git gettext \
          libgtk-3-dev libwxgtk3.0-gtk3-dev libssl-dev \
          libcurl4-openssl-dev libglu1-mesa-dev libdbus-1-dev \
          extra-cmake-modules pkgconf libudev-dev libglew-dev libhidapi-dev &&
        cd deps && mkdir -p build && cd build &&
        cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo &&
        ninja &&
        cd ../.. &&
        mkdir -p build && cd build &&
        cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DSLIC3R_STATIC=ON -DSLIC3R_GUI=ON &&
        ninja
      "
```

### Run with Docker Compose

```bash
docker-compose up
```

---

## Troubleshooting

### "Docker daemon is not running"

**Fix:**
1. Start Docker Desktop
2. Wait for it to fully start (whale icon in system tray)
3. Retry `act` command

---

### "Cannot pull Docker image"

**Issue:** Large images (10GB), slow download

**Fix:**
- Use smaller image: `act -P ubuntu-22.04=node:16-buster`
- Or wait for full image (one-time download)

---

### "Workflow fails with permissions error"

**Fix:**
```bash
# Run with sudo (Linux) or Administrator (Windows)
act workflow_dispatch --job build-linux
```

---

### "Out of disk space"

**Issue:** Docker images are large

**Fix:**
1. Clean up Docker:
   ```bash
   docker system prune -a
   ```
2. Free up disk space (need ~20GB free)
3. Retry

---

### "Job skipped"

**Issue:** Workflow trigger doesn't match

**Fix:**
```bash
# Use correct trigger event
act workflow_dispatch  # For manual triggers
act push              # For push triggers
```

---

## Advanced Usage

### Run Specific Step
```bash
# Dry run to see steps
act workflow_dispatch --job build-linux --dryrun

# Run specific step
act workflow_dispatch --job build-linux --step "Build Dependencies"
```

### Use Different Runner Image
```bash
# Use smaller image (faster, but may miss tools)
act -P ubuntu-22.04=node:16-buster \
  workflow_dispatch --job build-linux

# Use full GitHub image (slower, but most compatible)
act -P ubuntu-22.04=ghcr.io/catthehacker/ubuntu:full-22.04 \
  workflow_dispatch --job build-linux
```

### Debug Mode
```bash
act workflow_dispatch --verbose --job build-linux
```

### Interactive Shell
```bash
# Drop into shell after failure
act workflow_dispatch --job build-linux --shell
```

---

## Comparison: act vs GitHub Actions

| Aspect | GitHub Actions | act (Local) |
|--------|---------------|-------------|
| **Setup** | None (cloud) | Docker + act install |
| **First Run** | 2-3 hours | 2-3 hours + image pull |
| **Subsequent Runs** | 2-3 hours | 1-2 hours (cached) |
| **Internet Required** | Yes (always) | Only for first pull |
| **Disk Space** | None | ~20GB |
| **Debugging** | Limited | Full control |
| **Cost** | Free (within limits) | Free (unlimited) |
| **Reliability** | 90% | 80% (some features unsupported) |

---

## When to Use act

**Use act when:**
- ✅ Testing workflow before pushing
- ✅ Rapid iteration on workflow
- ✅ Debugging workflow issues
- ✅ Don't want to spam GitHub with builds
- ✅ Want to build offline (after initial setup)

**Use GitHub Actions when:**
- ✅ Want easiest setup (no Docker)
- ✅ Need multi-platform builds
- ✅ Want to share builds with team
- ✅ Don't want to use local disk space
- ✅ Want most reliable environment

---

## Linux Build in act (Recommended)

Linux build is fastest and most reliable in `act`:

```bash
cd "J:\github orca\OrcaSlicer"

# Run Linux build
act workflow_dispatch \
  --job build-linux \
  --input build_type=RelWithDebInfo \
  --verbose
```

**Why Linux:**
- ✅ Smaller Docker images
- ✅ Faster builds (~50% faster than Windows)
- ✅ Better Docker support
- ✅ More reliable

**Output:**
- `package/OrcaSlicer-CustomFeatures-*-Linux.tar.gz`

---

## Windows Build in act (Advanced)

Windows containers are more complex:

```bash
# Requires Windows containers enabled in Docker Desktop
act workflow_dispatch \
  --job build-windows \
  --input build_type=RelWithDebInfo
```

**Issues:**
- ⚠️ Windows containers larger (~20GB)
- ⚠️ Slower builds
- ⚠️ Requires Windows Server license (for full features)
- ⚠️ May not work perfectly

**Recommendation:** Use Linux build in act, Windows build in GitHub Actions

---

## Quick Reference

### Installation
```bash
# Install Docker Desktop (manual download)
# Then install act:
choco install act-cli

# Verify
docker --version
act --version
```

### Run Workflow
```bash
# List workflows
act -l

# Run Linux build (recommended)
act workflow_dispatch --job build-linux --input build_type=RelWithDebInfo

# Run with verbose output
act workflow_dispatch --job build-linux --verbose
```

### Troubleshooting
```bash
# Check Docker
docker ps
docker images

# Clean up
docker system prune -a

# Debug workflow
act workflow_dispatch --job build-linux --dryrun
```

---

## Next Steps

After successful local build:

1. ✅ Test executable: Extract artifact and run
2. ✅ Fix local environment: See ADDITIONAL-BUILD-STRATEGIES.md
3. ✅ Push to GitHub: Trigger cloud build for multi-platform

---

## Resources

- **act GitHub:** https://github.com/nektos/act
- **act Documentation:** https://nektosact.com/
- **Docker Desktop:** https://www.docker.com/products/docker-desktop/
- **GitHub Actions Docs:** https://docs.github.com/en/actions

---

**Status:** act setup ready ✅
**Time:** 30 minutes (install) + 2-3 hours (first build)
**Recommended:** Use Linux build job for fastest/most reliable results
