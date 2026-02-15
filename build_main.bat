@echo off
call "J:\visualstudio\vs2022\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 exit /b 1

set "PATH=J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin;%PATH%"
REM Remove MSYS usr/bin and Strawberry Perl paths that conflict with MSVC linker
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=%PATH:C:\Strawberry\perl\bin;=%"
set "PATH=%PATH:C:\Strawberry\c\bin;=%"
REM Add Git paths for git-submodule support
set "PATH=C:\Program Files\Git\mingw64\libexec\git-core;C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\bin;%PATH%"

cd /d "J:\github orca\OrcaSlicer\build"

echo Configuring OrcaSlicer with CMake (x64)...
"J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe" .. -G "Ninja" -DORCA_TOOLS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER="J:/visualstudio/vs2022/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe" -DCMAKE_CXX_COMPILER="J:/visualstudio/vs2022/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe"
if %ERRORLEVEL% NEQ 0 exit /b 1

echo.
echo Building OrcaSlicer...
"J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe" --build . --config Release
if %ERRORLEVEL% NEQ 0 exit /b 1

echo Build complete!
