@REM OrcaSlicer build script for Windows with VS auto-detect
@echo off
set WP=%CD%

@REM Check for Ninja Multi-Config option (-x)
set USE_NINJA=0
for %%a in (%*) do (
    if "%%a"=="-x" set USE_NINJA=1
)

if "%USE_NINJA%"=="1" (
    echo Using Ninja Multi-Config generator
    set CMAKE_GENERATOR="Ninja Multi-Config"
    set VS_VERSION=Ninja
    goto :generator_ready
)

@REM Detect Visual Studio version using vswhere (preferred) or msbuild
echo Detecting Visual Studio version...

set VS_MAJOR=
set VSWHERE="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"

@REM Try vswhere first (most reliable method)
if exist %VSWHERE% (
    echo Using vswhere to detect Visual Studio...
    for /f "usebackq tokens=*" %%i in (`%VSWHERE% -latest -property installationVersion`) do (
        set VS_VERSION_FULL=%%i
        for /f "tokens=1 delims=." %%a in ("%%i") do set VS_MAJOR=%%a
    )
    if not "%VS_MAJOR%"=="" (
        echo Visual Studio version detected: %VS_VERSION_FULL% (major: %VS_MAJOR%)
        goto :version_found
    )
)

@REM Fallback: Try to get MSBuild version
echo Trying MSBuild detection...
for /f "tokens=*" %%i in ('msbuild -version 2^>^&1 ^| findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
    for /f "tokens=1 delims=." %%a in ("%%i") do set VS_MAJOR=%%a
    set MSBUILD_OUTPUT=%%i
    goto :version_found
)

@REM Alternative method for newer MSBuild versions
if "%VS_MAJOR%"=="" (
    for /f "tokens=*" %%i in ('msbuild -version 2^>^&1 ^| findstr /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
        for /f "tokens=1 delims=." %%a in ("%%i") do set VS_MAJOR=%%a
        set MSBUILD_OUTPUT=%%i
        goto :version_found
    )
)

:version_found
if "%VS_MAJOR%"=="" (
    echo.
    echo Error: Could not determine Visual Studio version
    echo.
    echo Please use one of these methods:
    echo   1. Run this script from "Developer PowerShell for VS" or "Developer Command Prompt for VS"
    echo   2. Install Visual Studio 2019 or 2022 with C++ Desktop Development workload
    echo   3. Use Ninja generator: build_release_vs.bat -x
    echo.
    exit /b 1
)

if "%VS_MAJOR%"=="16" (
    set VS_VERSION=2019
    set CMAKE_GENERATOR="Visual Studio 16 2019"
) else if "%VS_MAJOR%"=="17" (
    set VS_VERSION=2022
    set CMAKE_GENERATOR="Visual Studio 17 2022"
) else if "%VS_MAJOR%"=="18" (
    @REM MSBuild 18.x is still part of VS 2022
    set VS_VERSION=2022
    set CMAKE_GENERATOR="Visual Studio 17 2022"
) else (
    echo Error: Unsupported Visual Studio version: %VS_MAJOR%
    echo Supported versions: VS2019 (16.x^), VS2022 (17.x-18.x^)
    exit /b 1
)

echo Detected Visual Studio %VS_VERSION% (version %VS_MAJOR%)
echo Using CMake generator: %CMAKE_GENERATOR%

:generator_ready

@REM Pack deps
if "%1"=="pack" (
    setlocal ENABLEDELAYEDEXPANSION 
    cd %WP%/deps/build
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do set build_date=%%c%%b%%a
    echo packing deps: OrcaSlicer_dep_win64_!build_date!_vs!VS_VERSION!.zip

    %WP%/tools/7z.exe a OrcaSlicer_dep_win64_!build_date!_vs!VS_VERSION!.zip OrcaSlicer_dep
    exit /b 0
)

set debug=OFF
set debuginfo=OFF
if "%1"=="debug" set debug=ON
if "%2"=="debug" set debug=ON
if "%1"=="debuginfo" set debuginfo=ON
if "%2"=="debuginfo" set debuginfo=ON
if "%debug%"=="ON" (
    set build_type=Debug
    set build_dir=build-dbg
) else (
    if "%debuginfo%"=="ON" (
        set build_type=RelWithDebInfo
        set build_dir=build-dbginfo
    ) else (
        set build_type=Release
        set build_dir=build
    )
)
echo build type set to %build_type%

setlocal DISABLEDELAYEDEXPANSION 
cd deps
mkdir %build_dir%
cd %build_dir%
set "SIG_FLAG="
if defined ORCA_UPDATER_SIG_KEY set "SIG_FLAG=-DORCA_UPDATER_SIG_KEY=%ORCA_UPDATER_SIG_KEY%"

if "%1"=="slicer" (
    GOTO :slicer
)
echo "building deps.."

echo on
REM Set minimum CMake policy to avoid <3.5 errors
set CMAKE_POLICY_VERSION_MINIMUM=3.5
if "%USE_NINJA%"=="1" (
    cmake ../ -G %CMAKE_GENERATOR% -DCMAKE_BUILD_TYPE=%build_type%
    cmake --build . --config %build_type% --target deps
) else (
    cmake ../ -G %CMAKE_GENERATOR% -A x64 -DCMAKE_BUILD_TYPE=%build_type%
    cmake --build . --config %build_type% --target deps -- -m
)
@echo off

if "%1"=="deps" exit /b 0

:slicer
echo "building Orca Slicer..."
cd %WP%
mkdir %build_dir%
cd %build_dir%

echo on
set CMAKE_POLICY_VERSION_MINIMUM=3.5
if "%USE_NINJA%"=="1" (
    cmake .. -G %CMAKE_GENERATOR% -DORCA_TOOLS=ON %SIG_FLAG% -DCMAKE_BUILD_TYPE=%build_type%
    cmake --build . --config %build_type% --target ALL_BUILD
) else (
    cmake .. -G %CMAKE_GENERATOR% -A x64 -DORCA_TOOLS=ON %SIG_FLAG% -DCMAKE_BUILD_TYPE=%build_type%
    cmake --build . --config %build_type% --target ALL_BUILD -- -m
)
@echo off
cd ..
call scripts/run_gettext.bat
cd %build_dir%
cmake --build . --target install --config %build_type%
