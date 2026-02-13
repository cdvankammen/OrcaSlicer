@REM OrcaSlicer build script for Windows with CMake 3.31.5
@echo off
set WP=%CD%

@REM Set CMAKE 3.31.5 path
set "CMAKE_PATH=%WP%\tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;%PATH%"

@REM Verify CMake version
echo Using CMake from: %CMAKE_PATH%
cmake --version
echo.

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
cmake ../ -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=%build_type%
cmake --build . --target deps
@echo off

if "%1"=="deps" exit /b 0

:slicer
echo "building Orca Slicer..."
cd %WP%
mkdir %build_dir%
cd %build_dir%

echo on
cmake .. -G "NMake Makefiles" -DORCA_TOOLS=ON %SIG_FLAG% -DCMAKE_BUILD_TYPE=%build_type%
cmake --build . --target ALL_BUILD
@echo off
cd ..
call scripts/run_gettext.bat
cd %build_dir%
cmake --build . --target install
