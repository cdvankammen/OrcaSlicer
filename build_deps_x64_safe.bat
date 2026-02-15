@echo off
setlocal
echo ============================================
echo Building OrcaSlicer Dependencies (x64)
echo Using ISOLATED directories: deps/build-x64
echo ============================================

REM Set up VS2026 x64 environment
echo Setting up Visual Studio 2026 x64 environment...
call "J:\visualstudio\vs studio\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to set up VS environment
    exit /b 1
)

REM Set up paths
set "CMAKE_PATH=%~dp0tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;C:\Strawberry\perl\bin;%PATH%"

REM Remove Git/MSYS paths to avoid conflicts
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=%PATH:C:\Program Files\Git\bin;=%"

echo.
echo CMake: %CMAKE_PATH%\cmake.exe
echo Perl: C:\Strawberry\perl\bin\perl.exe
echo Build Directory: deps\build-x64 (ISOLATED)
echo.

REM Build dependencies in build-x64
cd deps
if not exist build-x64 mkdir build-x64
cd build-x64

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
echo Location: deps\build-x64\OrcaSlicer_dep
echo.
echo Verifying Boost architecture...
findstr /i "x64 64bit" OrcaSlicer_dep\usr\local\lib\cmake\boost_filesystem-1.84.0\boost_filesystem-config.cmake
if %ERRORLEVEL% EQU 0 (
    echo OK: Boost is 64-bit
) else (
    echo WARNING: Boost may not be 64-bit
)

exit /b 0
