@echo off
REM ============================================
REM Wait for Dependencies then Build OrcaSlicer
REM Fixed version - waits for actual completion
REM ============================================

setlocal enabledelayedexpansion

set "TASK_OUTPUT=C:\Users\chris\AppData\Local\Temp\claude\J--github-orca-OrcaSlicer\tasks\b98df4b.output"
set "CHECK_INTERVAL=180"
set "MAX_WAIT=3600"
set "ELAPSED=0"

echo ============================================
echo Waiting for Dependency Build to Complete
echo ============================================
echo.
echo Task: b98df4b
echo Max wait: %MAX_WAIT% seconds (1 hour)
echo Check interval: %CHECK_INTERVAL% seconds
echo.

:wait_loop
if %ELAPSED% GEQ %MAX_WAIT% (
    echo.
    echo TIMEOUT: Dependencies took longer than 1 hour
    exit /b 1
)

echo [%TIME%] Checking for completion... (Elapsed: %ELAPSED%s)

REM Check for actual completion message
findstr /C:"Dependencies built successfully" "%TASK_OUTPUT%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo DEPENDENCIES COMPLETE!
    echo ============================================
    goto build_orcaslicer
)

REM Check for actual build errors (not CMake test failures)
findstr /C:"error: " /C:"CMake Error at" /C:"FAILED:" /C:"ninja: build stopped" "%TASK_OUTPUT%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo.
    echo WARNING: Possible error detected
    echo Last 50 lines:
    tail -50 "%TASK_OUTPUT%"
    echo.
    echo Waiting another cycle to confirm...
)

timeout /t %CHECK_INTERVAL% /nobreak >nul
set /a ELAPSED+=%CHECK_INTERVAL%
goto wait_loop

:build_orcaslicer
echo.
echo ============================================
echo BUILDING ORCASLICER
echo ============================================
echo.

cd /d "%~dp0"
call build_orcaslicer_x64_safe.bat

set BUILD_EXIT=%ERRORLEVEL%

echo.
echo ============================================
if %BUILD_EXIT% EQU 0 (
    echo BUILD SUCCESSFUL!
    echo.
    echo Executable: build-x64\OrcaSlicer\orca-slicer.exe
    echo.
    if exist "build-x64\OrcaSlicer\orca-slicer.exe" (
        echo ✓ Executable verified
        for %%A in ("build-x64\OrcaSlicer\orca-slicer.exe") do echo   Size: %%~zA bytes
    ) else (
        echo ERROR: Executable not found!
    )
) else (
    echo BUILD FAILED!
    echo Exit code: %BUILD_EXIT%
)
echo ============================================

exit /b %BUILD_EXIT%
