@echo off
call "J:\visualstudio\vs2022\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 exit /b 1

set "PATH=J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin;%PATH%"
REM Keep Git bin and add libexec/git-core for git-submodule, but remove usr/bin to avoid MSYS conflicts
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"
set "PATH=C:\Program Files\Git\mingw64\libexec\git-core;C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\bin;%PATH%"

cd /d "J:\github orca\OrcaSlicer\deps\build"

echo Building wxWidgets...
"J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe" --build . --target dep_wxWidgets
if %ERRORLEVEL% NEQ 0 exit /b 1

echo wxWidgets build complete!
