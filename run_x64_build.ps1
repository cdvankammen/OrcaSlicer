# OrcaSlicer x64 Build Script
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Building OrcaSlicer Dependencies (x64)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build dependencies
Write-Host "Step 1: Building dependencies (30-60 minutes)..." -ForegroundColor Yellow
& "$PSScriptRoot\build_deps_x64.bat"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Dependency build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Dependencies built successfully!" -ForegroundColor Green
Write-Host ""

# Step 2: Build OrcaSlicer
Write-Host "Step 2: Building OrcaSlicer (10-20 minutes)..." -ForegroundColor Yellow
& "$PSScriptRoot\build_orcaslicer_x64.bat"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: OrcaSlicer build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Executable: build\OrcaSlicer\Release\orca-slicer.exe" -ForegroundColor Cyan
