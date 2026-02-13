@echo off
echo ========================================
echo OrcaSlicer Build Script with VS 2022
echo ========================================
echo.

REM Check if VS 2022 is installed
if exist "J:\visualstudio\vs2022\VC\Auxiliary\Build\vcvarsall.bat" (
    echo [OK] VS 2022 found at J:\visualstudio\vs2022
) else (
    echo [ERROR] VS 2022 not found at J:\visualstudio\vs2022
    echo Please install VS 2022 Community to that location first.
    pause
    exit /b 1
)

echo.
echo Starting build process...
echo This will take 30-60 minutes.
echo.
echo Progress will be logged to build_progress.log
echo.

REM Run the standard build script
call build_release_vs2022.bat > build_progress.log 2>&1

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo BUILD SUCCESSFUL!
    echo ========================================
    echo.
    echo Solution file: build\OrcaSlicer.sln
    echo.
    echo Opening in Visual Studio...
    start "" "build\OrcaSlicer.sln"
) else (
    echo.
    echo ========================================
    echo BUILD FAILED - Check build_progress.log
    echo ========================================
    type build_progress.log | findstr /i "error"
)

pause
