@echo off
setlocal
set WP=%CD%

echo ========================================
echo OrcaSlicer CLEAN BUILD (x64)
echo ========================================
echo.

REM Set up VS 2022 environment (x64 for modern processors)
echo Setting up Visual Studio 2022 x64 environment...
call "J:\visualstudio\vs2022\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to set up VS environment
    exit /b 1
)

REM Set CMAKE 3.31.5 and Perl paths
set "CMAKE_PATH=%WP%\tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;C:\Strawberry\perl\bin;%PATH%"

REM Remove ONLY Git/MSYS usr/bin (Unix link.exe) but keep Git bin (git.exe)
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
REM Keep: C:\Program Files\Git\bin (needed for git commands)

set build_type=Release
set build_dir=build

echo.
echo ======== Building OrcaSlicer ========
echo.
echo [NOTE] Dependencies already built - using existing
echo.

cd %WP%
cd %build_dir%

echo Configuring OrcaSlicer with VS 2022 x64...
"%CMAKE_PATH%\cmake.exe" .. -G "Ninja" -DORCA_TOOLS=ON -DCMAKE_BUILD_TYPE=%build_type%
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] OrcaSlicer configuration failed!
    exit /b 1
)

echo.
echo Building OrcaSlicer...
"%CMAKE_PATH%\cmake.exe" --build . --config %build_type%
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] OrcaSlicer build failed!
    exit /b 1
)

echo.
echo Running gettext localization...
cd ..
call scripts\run_gettext.bat
cd %build_dir%

echo.
echo Installing to output directory...
"%CMAKE_PATH%\cmake.exe" --build . --target install --config %build_type%

echo.
echo ========================================
echo BUILD SUCCESSFUL!
echo ========================================
echo.
echo Executable: %WP%\%build_dir%\OrcaSlicer\orca-slicer.exe
echo.

exit /b 0
