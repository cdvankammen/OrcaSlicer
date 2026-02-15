@echo off
REM Build OrcaSlicer with proper x64 environment

REM Set x64 library paths
set "MSVC_ROOT=J:\visualstudio\vs studio\VC\Tools\MSVC\14.50.35717"
set "SDK_ROOT=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.26100.0"

REM Set LIB environment to x64 paths
set "LIB=%MSVC_ROOT%\lib\x64;%SDK_ROOT%\Lib\%SDK_VER%\um\x64;%SDK_ROOT%\Lib\%SDK_VER%\ucrt\x64"

REM Set LIBPATH for additional library search
set "LIBPATH=%MSVC_ROOT%\lib\x64;%SDK_ROOT%\Lib\%SDK_VER%\um\x64;%SDK_ROOT%\Lib\%SDK_VER%\ucrt\x64"

REM Set INCLUDE paths
set "INCLUDE=%MSVC_ROOT%\include;%SDK_ROOT%\Include\%SDK_VER%\um;%SDK_ROOT%\Include\%SDK_VER%\ucrt;%SDK_ROOT%\Include\%SDK_VER%\shared"

REM Set PATH to include x64 compiler first
set "PATH=%MSVC_ROOT%\bin\Hostx64\x64;%SDK_ROOT%\bin\%SDK_VER%\x64;%PATH%"

REM Display settings
echo LIB=%LIB%
echo.
echo PATH (first part)=%MSVC_ROOT%\bin\Hostx64\x64
echo.

REM Change to project root
cd /d "J:\github orca\OrcaSlicer"

REM Clean build directory
if exist "build\CMakeFiles" (
    echo Cleaning build directory...
    rd /s /q "build\CMakeFiles"
)
if exist "build\CMakeCache.txt" (
    del "build\CMakeCache.txt"
)

REM Create build directory if it doesn't exist
if not exist "build" mkdir build

REM Configure with CMake - explicitly specify compilers
echo Configuring OrcaSlicer...
cd build
"..\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe" .. -G "Ninja" ^
    -DCMAKE_BUILD_TYPE=Debug ^
    -DSLIC3R_ENC_CHECK=OFF ^
    -DCMAKE_C_COMPILER="%MSVC_ROOT%\bin\Hostx64\x64\cl.exe" ^
    -DCMAKE_CXX_COMPILER="%MSVC_ROOT%\bin\Hostx64\x64\cl.exe"

if errorlevel 1 (
    echo CMake configuration failed!
    exit /b 1
)

REM Build OrcaSlicer
echo Building OrcaSlicer...
"..\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe" --build . --config Debug --target OrcaSlicer

if errorlevel 1 (
    echo OrcaSlicer build failed!
    exit /b 1
)

echo OrcaSlicer build completed successfully!
