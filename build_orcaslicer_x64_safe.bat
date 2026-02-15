@echo off
setlocal
echo ============================================
echo Building OrcaSlicer Application (x64)
echo Using ISOLATED directory: build-x64
echo ============================================

REM Set up VS2026 x64 environment
call "J:\visualstudio\vs studio\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 exit /b 1

REM Set up paths
set "CMAKE_PATH=%~dp0tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;C:\Strawberry\perl\bin;%PATH%"
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=%PATH:C:\Program Files\Git\bin;=%"

echo Build Directory: build-x64 (ISOLATED)
echo Dependencies: deps\build-x64
echo.

REM Build OrcaSlicer in build-x64
if not exist build-x64 mkdir build-x64
cd build-x64

echo Configuring OrcaSlicer...
"%CMAKE_PATH%\cmake.exe" .. -G "Ninja" -DORCA_TOOLS=ON -DCMAKE_BUILD_TYPE=Release -DDEP_BUILD_DIR=%~dp0deps\build-x64
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Configuration failed
    exit /b 1
)

echo.
echo Building OrcaSlicer (this will take 10-20 minutes)...
echo Start time: %TIME%
echo.
"%CMAKE_PATH%\cmake.exe" --build .
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    exit /b 1
)

cd ..
echo Running gettext...
call scripts\run_gettext.bat

cd build-x64
echo Installing...
"%CMAKE_PATH%\cmake.exe" --build . --target install --config Release

echo.
echo ============================================
echo BUILD SUCCESSFUL!
echo ============================================
echo.
echo Executable: %~dp0build-x64\OrcaSlicer\orca-slicer.exe
echo.

exit /b 0
