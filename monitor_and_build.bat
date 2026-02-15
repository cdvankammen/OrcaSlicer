@echo off
REM ============================================
REM Automated Monitor & Build Script
REM Implements BUILD-STRATEGY-PLAN.md
REM ============================================

setlocal enabledelayedexpansion

echo ============================================
echo OrcaSlicer Automated Build Monitor
echo ============================================
echo.
echo This script will:
echo 1. Monitor dependency build completion
echo 2. Validate dependencies (Boost x64 check)
echo 3. Build OrcaSlicer automatically
echo 4. Report results
echo.
echo Press Ctrl+C to cancel at any time
echo.

REM Configuration
set "TASK_OUTPUT=C:\Users\chris\AppData\Local\Temp\claude\J--github-orca-OrcaSlicer\tasks\b98df4b.output"
set "DEPS_DIR=%~dp0deps\build-x64"
set "BUILD_SCRIPT=%~dp0build_orcaslicer_x64_safe.bat"
set "CHECK_INTERVAL=180"

REM Phase 1: Monitor dependency build
echo ============================================
echo PHASE 1: Monitoring Dependency Build
echo ============================================
echo Task output: %TASK_OUTPUT%
echo Check interval: %CHECK_INTERVAL% seconds
echo.

:monitor_loop
echo [%TIME%] Checking build status...

REM Check if output file exists
if not exist "%TASK_OUTPUT%" (
    echo ERROR: Task output file not found!
    echo File: %TASK_OUTPUT%
    exit /b 1
)

REM Check for completion message
findstr /C:"Dependencies built successfully" "%TASK_OUTPUT%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo DEPENDENCY BUILD COMPLETE!
    echo ============================================
    goto validate_deps
)

REM Check for errors
findstr /I /C:"error:" /C:"failed" "%TASK_OUTPUT%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo ERROR DETECTED IN BUILD
    echo ============================================
    echo Last 50 lines of output:
    tail -50 "%TASK_OUTPUT%"
    echo.
    echo Check BUILD-JOURNAL.md Error Catalog for solutions
    exit /b 1
)

REM Show progress
echo Current status:
tail -5 "%TASK_OUTPUT%"
echo.
echo Waiting %CHECK_INTERVAL% seconds before next check...
timeout /t %CHECK_INTERVAL% /nobreak >nul
goto monitor_loop

:validate_deps
REM Phase 2: Validate dependencies
echo.
echo ============================================
echo PHASE 2: Validating Dependencies
echo ============================================
echo.

REM Check if deps directory exists
if not exist "%DEPS_DIR%" (
    echo ERROR: Dependency directory not found!
    echo Expected: %DEPS_DIR%
    exit /b 1
)

echo Checking Boost architecture...
set "BOOST_CONFIG=%DEPS_DIR%\OrcaSlicer_dep\usr\local\lib\cmake\boost_filesystem-1.84.0\boost_filesystem-config.cmake"

if not exist "%BOOST_CONFIG%" (
    echo WARNING: Boost config file not found
    echo File: %BOOST_CONFIG%
    echo Continuing anyway...
    goto build_orcaslicer
)

findstr /I "x64 64-bit x86_64" "%BOOST_CONFIG%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ Boost is 64-bit (x64)
) else (
    echo WARNING: Could not confirm Boost is 64-bit
    findstr /I "32-bit x86" "%BOOST_CONFIG%" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo ERROR: Boost is 32-bit!
        echo This will cause build failure.
        exit /b 1
    )
)

REM Count libraries
echo.
echo Counting installed libraries...
dir /b "%DEPS_DIR%\OrcaSlicer_dep\usr\local\lib\*.lib" 2>nul | find /c /v "" >temp_count.txt
set /p LIB_COUNT=<temp_count.txt
del temp_count.txt
echo Found %LIB_COUNT% library files

if %LIB_COUNT% LSS 50 (
    echo WARNING: Expected more libraries (should be 100+)
    echo Continuing anyway...
)

echo.
echo ============================================
echo VALIDATION COMPLETE
echo ============================================

:build_orcaslicer
REM Phase 3: Build OrcaSlicer
echo.
echo ============================================
echo PHASE 3: Building OrcaSlicer
echo ============================================
echo.

if not exist "%BUILD_SCRIPT%" (
    echo ERROR: Build script not found!
    echo Expected: %BUILD_SCRIPT%
    exit /b 1
)

echo Build script: %BUILD_SCRIPT%
echo Start time: %TIME%
echo.
echo Starting build (this will take 10-20 minutes)...
echo.

call "%BUILD_SCRIPT%"
set BUILD_EXIT_CODE=%ERRORLEVEL%

echo.
echo ============================================
if %BUILD_EXIT_CODE% EQU 0 (
    echo BUILD SUCCESSFUL!
) else (
    echo BUILD FAILED!
    echo Exit code: %BUILD_EXIT_CODE%
)
echo End time: %TIME%
echo ============================================
echo.

REM Phase 4: Verify executable
if %BUILD_EXIT_CODE% EQU 0 (
    echo.
    echo ============================================
    echo PHASE 4: Verifying Executable
    echo ============================================
    echo.

    set "EXE_PATH=%~dp0build-x64\OrcaSlicer\orca-slicer.exe"

    if exist "!EXE_PATH!" (
        echo ✓ Executable found: !EXE_PATH!

        REM Get file size
        for %%A in ("!EXE_PATH!") do set EXE_SIZE=%%~zA
        echo   Size: !EXE_SIZE! bytes

        REM Get timestamp
        for %%A in ("!EXE_PATH!") do set EXE_DATE=%%~tA
        echo   Modified: !EXE_DATE!

        echo.
        echo ============================================
        echo COMPLETE SUCCESS!
        echo ============================================
        echo.
        echo Next steps:
        echo 1. Test Feature #2: Per-plate settings
        echo 2. Test Feature #5: Hierarchical grouping
        echo 3. Test Feature #6: Cutting plane
        echo 4. Test Features #3, #4: Multi-material flush
        echo 5. Integration testing
        echo.
        echo See BUILD-STRATEGY-PLAN.md Phase 5 for testing procedures
        echo.
    ) else (
        echo ERROR: Executable not found!
        echo Expected: !EXE_PATH!
        exit /b 1
    )
)

exit /b %BUILD_EXIT_CODE%
