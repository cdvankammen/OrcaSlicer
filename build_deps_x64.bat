@echo off
setlocal
echo ============================================
echo Building OrcaSlicer Dependencies (x64)
echo ============================================

REM Set up VS2022 x64 environment
echo Setting up Visual Studio 2022 x64 environment...
call "J:\visualstudio\vs2022\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to set up VS environment
    exit /b 1
)

REM Set up paths
set "CMAKE_PATH=%~dp0tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;C:\Strawberry\perl\bin;%PATH%"

REM Remove ONLY Git/MSYS usr/bin (Unix link.exe) but keep Git bin (git.exe, git-submodule)
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
REM Keep: C:\Program Files\Git\bin (needed for git submodule)

echo.
echo CMake: %CMAKE_PATH%\cmake.exe
echo Perl: C:\Strawberry\perl\bin\perl.exe
echo.

REM Build dependencies
cd deps
if not exist build mkdir build
cd build

echo Configuring dependencies (Ninja + Release + x64)...
"%CMAKE_PATH%\cmake.exe" .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake configuration failed
    exit /b 1
)

echo.
echo Building dependencies (this will take 30-60 minutes)...
echo Start time: %TIME%
echo.
"%CMAKE_PATH%\cmake.exe" --build . --target deps
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Dependency build failed
    exit /b 1
)

echo.
echo ============================================
echo Dependencies built successfully!
echo End time: %TIME%
echo ============================================
echo.
echo Verifying Boost architecture...
findstr /i "x64 64bit" OrcaSlicer_dep\usr\local\lib\cmake\boost_filesystem-1.84.0\boost_filesystem-config.cmake
if %ERRORLEVEL% EQU 0 (
    echo OK: Boost is 64-bit
) else (
    echo WARNING: Boost may not be 64-bit
    echo Check: deps\build\OrcaSlicer_dep\usr\local\lib\cmake\boost_filesystem-1.84.0\boost_filesystem-config.cmake
)

exit /b 0
