@echo off
call "J:\visualstudio\vs studio\VC\Auxiliary\Build\vcvarsall.bat" x64
cd "J:\github orca\OrcaSlicer\deps\build"
"J:\github orca\OrcaSlicer\tools\cmake-3.31.5-windows-x86_64\bin\cmake.exe" ../ -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release
