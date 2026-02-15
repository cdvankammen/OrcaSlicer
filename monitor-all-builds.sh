#!/bin/bash
# Monitor all builds in parallel

echo "================================================"
echo "Monitoring All Build Processes"
echo "================================================"
echo ""

while true; do
    clear
    echo "========== BUILD STATUS =========="
    echo "Time: $(date '+%H:%M:%S')"
    echo ""
    
    # MinGW Build Status
    echo "=== MinGW Local Build ==="
    if [ -f "deps/build-local/deps-build.log" ]; then
        LAST_LINE=$(tail -1 "deps/build-local/deps-build.log")
        echo "$LAST_LINE"
        PROGRESS=$(grep -o "\[[0-9]*/[0-9]*\]" "deps/build-local/deps-build.log" | tail -1)
        echo "Progress: $PROGRESS"
    else
        echo "Not started yet"
    fi
    echo ""
    
    # GitHub Actions Status
    echo "=== GitHub Actions Build ==="
    gh run list --repo cdvankammen/OrcaSlicer --workflow=build-custom-features.yml --limit 1 2>/dev/null || echo "No runs found"
    echo ""
    
    # Ninja processes
    NINJA_COUNT=$(tasklist.exe 2>/dev/null | grep -c ninja.exe || echo 0)
    echo "Ninja processes: $NINJA_COUNT"
    echo ""
    
    echo "Press Ctrl+C to stop monitoring"
    sleep 10
done
