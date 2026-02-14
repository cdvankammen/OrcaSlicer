@echo off
setlocal
set WP=%CD%

echo Setting up VS environment...
call "J:\visualstudio\vs studio\VC\Auxiliary\Build\vcvarsall.bat" x64

echo Setting up paths...
set "CMAKE_PATH=%WP%\tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;C:\Strawberry\perl\bin;%PATH%"

echo Removing Git/MSYS paths...
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=%PATH:C:\Program Files\Git\bin;=%"

set build_type=Release
set build_dir=build

echo.
echo ======== Building OrcaSlicer ========
echo.
cd %WP%
cd %build_dir%

echo Configuring OrcaSlicer...
"%CMAKE_PATH%\cmake.exe" .. -G "Ninja" -DORCA_TOOLS=ON -DCMAKE_BUILD_TYPE=%build_type%
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] OrcaSlicer configuration failed!
    exit /b 1
)

echo Building OrcaSlicer...
"%CMAKE_PATH%\cmake.exe" --build .
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] OrcaSlicer build failed!
    exit /b 1
)

echo.
echo ========================================
echo BUILD SUCCESSFUL!
echo ========================================
echo.

exit /b 0
