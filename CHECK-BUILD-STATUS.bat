@echo off
echo ================================================
echo Checking GitHub Actions Build Status
echo ================================================
echo.

gh run list --repo cdvankammen/OrcaSlicer --workflow=build-custom-features.yml --limit 5

echo.
echo ================================================
echo.
echo To trigger build:
echo   1. Go to: https://github.com/cdvankammen/OrcaSlicer/actions
echo   2. Click "Build OrcaSlicer with Custom Features"
echo   3. Click "Run workflow"
echo   4. Select branch: cdv-personal
echo   5. Click green "Run workflow" button
echo.
echo To monitor build:
echo   bash monitor-build.sh
echo.
pause
