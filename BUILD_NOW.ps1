# OrcaSlicer Build Script - x64 without CGAL
# Run this directly in PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OrcaSlicer Build (x64 - No CGAL)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Set paths
$rootDir = "J:\github orca\OrcaSlicer"
$buildDir = "$rootDir\build"
$cmakePath = "$rootDir\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe"
$vsPath = "J:\visualstudio\vs2022\VC\Auxiliary\Build\vcvarsall.bat"

Write-Host "Step 1: Setting up Visual Studio 2022 x64 environment..." -ForegroundColor Yellow

# Create a temporary batch file to set up VS environment and run cmake
$tempBat = "$env:TEMP\orcabuild.bat"
@"
@echo off
call "$vsPath" x64
if %ERRORLEVEL% NEQ 0 exit /b 1

set "PATH=J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin;C:\Strawberry\perl\bin;%PATH%"
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=%PATH:C:\Program Files\Git\bin;=%"

cd /d "$buildDir"

echo Configuring with CMake...
"$cmakePath" .. -G "Ninja" -DORCA_TOOLS=ON -DCMAKE_BUILD_TYPE=Release
if %ERRORLEVEL% NEQ 0 exit /b 1

echo Building OrcaSlicer...
"$cmakePath" --build . --config Release
if %ERRORLEVEL% NEQ 0 exit /b 1

echo Build complete!
"@ | Out-File -FilePath $tempBat -Encoding ASCII

Write-Host "Step 2: Running build (this will take 10-20 minutes)..." -ForegroundColor Yellow
Write-Host ""

# Run the batch file
& cmd /c "$tempBat"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Build FAILED!" -ForegroundColor Red
    Write-Host "Check the output above for errors." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Find the executable
$exeLocations = @(
    "$buildDir\OrcaSlicer\orca-slicer.exe",
    "$buildDir\src\orca-slicer.exe",
    "$buildDir\OrcaSlicer\Release\orca-slicer.exe"
)

$exePath = $null
foreach ($loc in $exeLocations) {
    if (Test-Path $loc) {
        $exePath = $loc
        break
    }
}

if ($exePath) {
    Write-Host "Executable: $exePath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To run OrcaSlicer, execute:" -ForegroundColor Yellow
    Write-Host "  & '$exePath'" -ForegroundColor White
} else {
    Write-Host "Warning: Could not locate executable in expected locations" -ForegroundColor Yellow
    Write-Host "Check the build directory: $buildDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
