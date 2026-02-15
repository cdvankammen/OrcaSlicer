# Fix Docker Issue - Daemon Not Responding

**Error:** `request returned 500 Internal Server Error for API route`

**Cause:** Docker daemon communication issue

---

## Quick Fix (2 minutes)

### Option 1: Restart Docker Desktop (Recommended)

1. **Right-click Docker Desktop icon** in system tray (bottom-right, near clock)
2. Click **"Restart"**
3. Wait 30-60 seconds for Docker to fully restart
4. Verify it's working:
   ```bash
   docker ps
   ```
5. If successful, restart build:
   ```bash
   cd "J:\github orca\OrcaSlicer"
   docker build -t orcaslicer-custom:latest .
   ```

---

### Option 2: Restart Docker Service (Alternative)

**Open PowerShell as Administrator:**
```powershell
# Stop Docker
net stop com.docker.service

# Start Docker
net start com.docker.service

# Wait 30 seconds
Start-Sleep -Seconds 30

# Test
docker ps
```

---

### Option 3: Full Restart (If Above Don't Work)

1. **Close Docker Desktop completely:**
   - Right-click system tray icon → "Quit Docker Desktop"
   - Or: Task Manager → End "Docker Desktop" process

2. **Wait 10 seconds**

3. **Start Docker Desktop:**
   - Start menu → "Docker Desktop"
   - Wait for "Docker Desktop is running" notification

4. **Verify:**
   ```bash
   docker ps
   docker version
   ```

5. **Restart build:**
   ```bash
   cd "J:\github orca\OrcaSlicer"
   docker build -t orcaslicer-custom:latest . | tee docker-build.log
   ```

---

## After Docker is Fixed

### Start the Build Again

```bash
cd "J:\github orca\OrcaSlicer"

# Build (will show progress in terminal)
docker build -t orcaslicer-custom:latest . 2>&1 | tee docker-build.log

# Or build in background
docker build -t orcaslicer-custom:latest . > docker-build.log 2>&1 &

# Monitor progress
tail -f docker-build.log
```

---

## If Docker Still Has Issues

### Check Docker Desktop Status

1. Open Docker Desktop application
2. Go to Settings → General
3. Check: "Use the WSL 2 based engine" (should be checked if WSL2 available)
4. Apply & Restart

### Alternative: Use WSL2 Instead

**If Docker continues having issues, WSL2 is more reliable:**

```powershell
# Enable WSL2 (PowerShell as Admin)
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all

# Restart computer
shutdown /r /t 60
```

**After restart:**
```bash
# Start WSL2
wsl --distribution Ubuntu

# Build directly in Ubuntu (see ACTION-PLAN-NOW.md)
```

---

## Alternative Paths (No Docker Needed)

While fixing Docker, you can proceed with:

### ✅ GitHub Actions (Already Set Up)
1. Go to: https://github.com/cdvankammen/OrcaSlicer/actions
2. Trigger "Build OrcaSlicer with Custom Features" workflow
3. Get Windows/Linux/macOS executables in 2-3 hours

### ✅ WSL2 Direct Build (Recommended if Docker fails)
See `ACTION-PLAN-NOW.md` Step 2

---

## Docker Troubleshooting Tips

### Check Docker Status
```bash
# Is Docker running?
tasklist.exe | grep -i docker

# Can we connect?
docker version

# What's the error?
docker info
```

### Reset Docker to Factory Settings
**Last resort if nothing works:**

1. Docker Desktop → Settings → Troubleshoot
2. Click "Reset to factory defaults"
3. Confirm reset
4. Restart Docker Desktop
5. Retry build

**Warning:** This deletes all Docker images and containers.

---

## Expected Build Output (When Working)

You should see:
```
[+] Building 0.1s (3/3) FINISHED
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 1.23kB
 => [internal] load .dockerignore
 => => transferring context: 2B
 => [internal] load metadata for docker.io/library/ubuntu:22.04

Step 1/8 : FROM ubuntu:22.04
 ---> <image_id>
Step 2/8 : ENV DEBIAN_FRONTEND=noninteractive
 ---> Using cache
 ---> <image_id>
...
```

If you see this, build is working! Let it run for 1-2 hours.

---

## Current Status

**What happened:**
- ✅ Docker Desktop is installed and running (processes detected)
- ❌ Docker daemon API not responding (500 error)
- ⏳ Build command failed before starting

**Next steps:**
1. Restart Docker Desktop (see Option 1 above)
2. Verify with `docker ps`
3. Restart build command
4. Or use GitHub Actions / WSL2 instead

---

**Don't worry!** You have multiple build paths:
- 🐳 Docker (fixing now)
- 🐧 WSL2 (easy to enable)
- ☁️ GitHub Actions (already set up)
- 🔨 VS2022 (if needed)

**At least one will work!** 🚀
