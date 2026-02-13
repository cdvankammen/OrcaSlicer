# OrcaSlicer build script for Windows PowerShell
$WP = Get-Location

# Set Visual Studio installation directory
$env:VSINSTALLDIR = "J:\visualstudio\vs studio\"
$env:VCINSTALLDIR = "J:\visualstudio\vs studio\VC\"

# Set CMAKE 3.31.5 path
$CMAKE_PATH = "$WP\tools\cmake-3.31.5-windows-x86_64\bin"
$env:PATH = "$CMAKE_PATH;$env:PATH"

# Verify CMake version
Write-Host "Using CMake from: $CMAKE_PATH"
& cmake --version
Write-Host ""

# Call vcvarsall to set up VS environment
Write-Host "Setting up Visual Studio environment..."
cmd /c "`"J:\visualstudio\vs studio\VC\Auxiliary\Build\vcvarsall.bat`" x64 && set" | ForEach-Object {
    if ($_ -match "^(.+?)=(.*)$") {
        Set-Item -Path "env:$($matches[1])" -Value $matches[2]
    }
}
Write-Host ""

$build_type = "Release"
$build_dir = "build"

Write-Host "build type set to $build_type"

# Build dependencies
Write-Host "Building deps..."
Set-Location deps
New-Item -ItemType Directory -Force -Path $build_dir | Out-Null
Set-Location $build_dir

Write-Host "Running cmake for dependencies..."
& cmake ../ -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=$build_type
if ($LASTEXITCODE -ne 0) {
    Write-Host "CMake configuration failed for dependencies"
    exit $LASTEXITCODE
}

Write-Host "Building dependencies..."
& cmake --build . --config $build_type --target deps -- -m
if ($LASTEXITCODE -ne 0) {
    Write-Host "Dependencies build failed"
    exit $LASTEXITCODE
}

# Build main slicer
Write-Host "Building Orca Slicer..."
Set-Location $WP
New-Item -ItemType Directory -Force -Path $build_dir | Out-Null
Set-Location $build_dir

Write-Host "Running cmake for Orca Slicer..."
& cmake .. -G "Visual Studio 17 2022" -A x64 -DORCA_TOOLS=ON -DCMAKE_BUILD_TYPE=$build_type
if ($LASTEXITCODE -ne 0) {
    Write-Host "CMake configuration failed for Orca Slicer"
    exit $LASTEXITCODE
}

Write-Host "Building Orca Slicer..."
& cmake --build . --config $build_type --target ALL_BUILD -- -m
if ($LASTEXITCODE -ne 0) {
    Write-Host "Orca Slicer build failed"
    exit $LASTEXITCODE
}

Set-Location ..
& .\scripts\run_gettext.bat
Set-Location $build_dir
& cmake --build . --target install --config $build_type

Write-Host "Build complete!"
