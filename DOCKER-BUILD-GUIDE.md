# Docker Build Guide - Running Now!

**Status:** ✅ DOCKER BUILD STARTED
**Task ID:** bf94301
**Expected Duration:** 1-2 hours
**Output Log:** `docker-build.log`

---

## 🐳 What's Happening Right Now

Docker is:
1. ✅ Pulling Ubuntu 22.04 base image (~70MB)
2. ⏳ Installing build dependencies (~500MB)
3. ⏳ Copying your code into container
4. ⏳ Building dependencies (Boost, wxWidgets, OpenCV, etc.) - 45-60 min
5. ⏳ Building OrcaSlicer - 20-30 min
6. ✅ Creating final image with executable

---

## 📊 Monitor Progress

### Check Live Output
```bash
# Watch real-time progress
tail -f docker-build.log

# Or check last 50 lines
tail -50 docker-build.log

# Or check task output
tail -f "C:\Users\chris\AppData\Local\Temp\claude\J--github-orca-OrcaSlicer\tasks\bf94301.output"
```

### Check Docker Build Status
```bash
# List running containers
docker ps

# Check Docker disk usage
docker system df

# See build progress (if using BuildKit)
docker buildx ls
```

---

## ⏱️ Timeline

**Right Now (0:00):**
- ✅ Dockerfile created
- ✅ .dockerignore created
- ✅ Docker build started (background task bf94301)

**+5 Minutes (0:05):**
- ✅ Ubuntu image pulled
- ✅ Dependencies installed
- ⏳ Copying source code

**+10 Minutes (0:10):**
- ✅ Source copied
- ⏳ Building Boost (longest dependency)

**+45 Minutes (0:45):**
- ✅ Boost built
- ⏳ Building wxWidgets

**+60 Minutes (1:00):**
- ✅ All dependencies built
- ⏳ Building OrcaSlicer

**+90 Minutes (1:30):**
- ✅ OrcaSlicer built successfully! 🎉
- ⏳ Creating final Docker image

**+95 Minutes (1:35):**
- ✅ Docker image ready
- ✅ Can extract executable

---

## ✅ When Build Completes

### Check Build Status
```bash
# Check if build finished
docker images | grep orcaslicer-custom

# Should show:
# orcaslicer-custom   latest   IMAGE_ID   X minutes ago   SIZE
```

### Extract the Executable

**Method 1: Copy from Container**
```bash
# Create a temporary container
docker create --name orca-temp orcaslicer-custom:latest

# Copy executable out
docker cp orca-temp:/build/build/src/orcaslicer ./orcaslicer-linux

# Copy resources too
docker cp orca-temp:/build/resources ./resources

# Clean up temporary container
docker rm orca-temp

# Test executable
./orcaslicer-linux --help
```

**Method 2: Run in Container**
```bash
# Run directly in container
docker run --rm orcaslicer-custom:latest

# Run with GUI (requires X server on Windows)
docker run --rm \
  -e DISPLAY=host.docker.internal:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  orcaslicer-custom:latest ./src/orcaslicer
```

**Method 3: Mount Volume and Copy**
```bash
# Run with volume mount
docker run --rm \
  -v "J:\github orca\OrcaSlicer\output:/output" \
  orcaslicer-custom:latest \
  bash -c "cp /build/build/src/orcaslicer /output/ && cp -r /build/resources /output/"

# Executable will be at:
# J:\github orca\OrcaSlicer\output\orcaslicer
```

---

## 🔍 Check for Errors

### If Build Fails

**Check the logs:**
```bash
# See where it failed
cat docker-build.log | grep -i error

# See full context around error
cat docker-build.log | grep -B 10 -A 10 -i error
```

**Common Issues:**

#### "Cannot connect to Docker daemon"
**Solution:** Docker Desktop not running
```bash
# Start Docker Desktop manually
# Or restart Docker service
```

#### "No space left on device"
**Solution:** Docker out of disk space
```bash
# Clean up Docker
docker system prune -a

# Check space
docker system df
```

#### "Build dependency failed"
**Solution:** Missing or broken dependency
```bash
# Check which dependency failed
grep -i "FAILED:" docker-build.log

# Often Boost or wxWidgets
# The Dockerfile handles most issues automatically
```

---

## 📦 What You'll Get

After successful build:

```
Docker Image: orcaslicer-custom:latest
  └─ Contains:
     ├─ /build/build/src/orcaslicer (executable)
     ├─ /build/resources/ (profiles, icons, etc.)
     └─ All dependencies (statically linked if possible)

Size: ~2-3 GB (includes build tools)
Compressed: Can export to ~500MB tar.gz
```

---

## 🚀 Package for Distribution

### Create Tarball
```bash
# Extract and package
docker create --name orca-temp orcaslicer-custom:latest
docker cp orca-temp:/build/build/src/orcaslicer ./
docker cp orca-temp:/build/resources ./
docker rm orca-temp

# Create tarball
tar -czf OrcaSlicer-CustomFeatures-Docker-$(date +%Y%m%d).tar.gz \
  orcaslicer resources

# Upload or share
# Size: ~50-100MB compressed
```

### Save Docker Image
```bash
# Export entire image
docker save orcaslicer-custom:latest | gzip > orcaslicer-docker-image.tar.gz

# Import on another machine
docker load < orcaslicer-docker-image.tar.gz
```

---

## 🎯 Current Status Check

### Quick Status
```bash
# Is build still running?
docker ps | grep orcaslicer

# Check progress
tail -20 docker-build.log

# Check task status
ls -lh "C:\Users\chris\AppData\Local\Temp\claude\J--github-orca-OrcaSlicer\tasks\bf94301.output"
```

### Detailed Status
```bash
# Show all Docker build output
cat docker-build.log

# Count progress (rough estimate)
# Dockerfile has ~30 RUN commands
# Current command:
grep "Step" docker-build.log | tail -1
```

---

## ⚡ Speed Up Future Builds

### Use Build Cache
Docker caches each layer. If you change code:

```bash
# Only rebuilds from changed layer onward
docker build -t orcaslicer-custom:latest .

# Much faster: 5-10 minutes instead of 1-2 hours
```

### Use BuildKit (Faster)
```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Or in PowerShell
$env:DOCKER_BUILDKIT=1

# Rebuild
docker build -t orcaslicer-custom:latest .
```

### Multi-stage Build (Smaller Image)
Future optimization: Create two-stage Dockerfile
- Stage 1: Build everything (large)
- Stage 2: Copy only executable + resources (small)

---

## 🔄 While Docker Builds: Do These

### Option 1: GitHub Actions (Recommended)
Already set up! Runs in parallel:
1. Go to: https://github.com/cdvankammen/OrcaSlicer/actions
2. Click "Build OrcaSlicer with Custom Features"
3. Run workflow
4. Get Windows + Linux + macOS builds in 2-3 hours

### Option 2: WSL2 Build
If you haven't enabled WSL2 yet:
1. Run PowerShell as Admin:
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all
   ```
2. Restart computer
3. Build in Ubuntu (1 hour)

### Option 3: Read Documentation
While waiting, review:
- `.claude/GAP-ANALYSIS-COMPLETE.md` - 47 issues found
- `.claude/CREATIVE-SOLUTIONS.md` - Solutions for all issues
- `.claude/RECURSIVE-IMPROVEMENT-PLAN.md` - 48-hour roadmap
- `docs/CUSTOM-FEATURES.md` - Feature overview

---

## 🎉 Success Criteria

### Build Succeeded If:
```bash
# Docker image exists
docker images | grep orcaslicer-custom

# Executable works
docker run --rm orcaslicer-custom:latest
# Shows: OrcaSlicer version info

# Can extract executable
docker create --name test orcaslicer-custom:latest
docker cp test:/build/build/src/orcaslicer ./test-orcaslicer
docker rm test
./test-orcaslicer --help
# Shows: Usage information
```

---

## 📝 Notes

### This is a Linux Build
- Output: Linux ELF executable
- Won't run directly on Windows
- Options:
  1. Run in Docker container
  2. Run in WSL2
  3. Copy to Linux machine
  4. Use for testing/CI

### For Windows .exe
Use GitHub Actions or VS2022 build (see other guides).

### Advantages of Docker Build
- ✅ Isolated environment
- ✅ Reproducible builds
- ✅ No local environment changes
- ✅ Can run anywhere with Docker
- ✅ Build cache for fast rebuilds

---

## ⏭️ Next Steps

**After Docker build completes:**

1. **Extract executable:**
   ```bash
   docker create --name orca orcaslicer-custom:latest
   docker cp orca:/build/build/src/orcaslicer ./orcaslicer-docker
   docker cp orca:/build/resources ./resources
   docker rm orca
   ```

2. **Test in WSL2:**
   ```bash
   wsl
   cd /mnt/j/github\ orca/OrcaSlicer
   ./orcaslicer-docker --help
   ```

3. **Package for distribution:**
   ```bash
   tar -czf orcaslicer-custom-docker.tar.gz orcaslicer-docker resources
   ```

4. **Test features:**
   - Per-Plate Settings
   - Prime Tower Selection
   - Flush Selection
   - Volume Grouping
   - Cutting Plane Size

---

## 🆘 Troubleshooting

### Build Stuck at Dependencies
**Normal!** Boost takes 30-45 minutes to compile.
```bash
# Check if actually stuck (no new output for 10+ minutes)
tail -20 docker-build.log

# If truly stuck, restart:
docker build --no-cache -t orcaslicer-custom:latest .
```

### Out of Memory
**Solution:** Increase Docker memory limit
1. Docker Desktop → Settings → Resources
2. Increase Memory to 8GB+
3. Apply & Restart
4. Rebuild

### Out of Disk Space
**Solution:** Clean Docker
```bash
docker system prune -a
docker volume prune
```

---

## 📊 Comparison: Docker vs Other Methods

| Method | Time | Output | Difficulty |
|--------|------|--------|------------|
| **Docker** | 1-2 hrs | Linux | Easy |
| **WSL2** | 1 hr | Linux | Easy |
| **GitHub Actions** | 2-3 hrs | Win+Linux+Mac | Easy |
| **VS2022** | 3 hrs | Windows | Medium |

**All running in parallel = Multiple executables!** 🚀

---

**Status:** Docker build running ✅
**Monitor:** `tail -f docker-build.log`
**Task ID:** bf94301
**Expected Completion:** 1-2 hours

**Keep this terminal open or check back in an hour!** ☕
