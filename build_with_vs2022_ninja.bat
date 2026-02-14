@echo off
setlocal
set WP=%CD%

echo ========================================
echo OrcaSlicer Build with VS 2022 + Ninja
echo ========================================
echo.

REM Set up VS 2022 environment
call "J:\visualstudio\vs2022\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Set CMAKE 3.31.5 and Perl paths - ensure Strawberry Perl before Git/MSYS
set "CMAKE_PATH=%WP%\tools\cmake-3.31.5-windows-x86_64\bin"
set "PATH=%CMAKE_PATH%;C:\Strawberry\perl\bin;%PATH%"

REM Remove Git/MSYS paths to avoid linker conflicts
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=%PATH:C:\Program Files\Git\bin;=%"

set build_type=Release
set build_dir=build

echo.
echo ======== Building OrcaSlicer ========
echo.
echo [NOTE] Dependencies already built - skipping deps build
echo.
cd %WP%
cd %build_dir%

echo Cleaning previous build...
del /Q *.ninja 2>nul
del /Q CMakeCache.txt 2>nul
rmdir /S /Q CMakeFiles 2>nul

echo Configuring OrcaSlicer with VS 2022...
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

cd ..
call scripts\run_gettext.bat
cd %build_dir%
"%CMAKE_PATH%\cmake.exe" --build . --target install --config %build_type%

echo.
echo ========================================
echo BUILD SUCCESSFUL!
echo ========================================
echo.
echo Executable: %WP%\%build_dir%\OrcaSlicer\orca-slicer.exe
echo.

exit /b 0
