@echo off
setlocal
echo ======================================================================
echo Final OrcaSlicer x64 Build
echo ======================================================================

REM Clean and create build directory
cd /d "J:\github orca\OrcaSlicer"
if exist build rmdir /s /q build
mkdir build
cd build

REM Set up proper x64 environment
call "J:\visualstudio\vs2022\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to set up VS2022 x64 environment
    exit /b 1
)

REM Configure with CMake
echo Configuring OrcaSlicer for x64...
"J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe" .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake configuration failed
    exit /b 1
)

REM Build
echo.
echo Building OrcaSlicer (this will take 10-20 minutes)...
echo Start time: %TIME%
echo.
"J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe" --build .
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    exit /b 1
)

echo.
echo ======================================================================
echo BUILD SUCCESSFUL!
echo ======================================================================
echo Executable: J:\github orca\OrcaSlicer\build\src\OrcaSlicer.exe
echo.

exit /b 0
