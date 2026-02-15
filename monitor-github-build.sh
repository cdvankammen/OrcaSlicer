#!/bin/bash
# Monitor GitHub Actions build 22035189629

RUN_ID="22035189629"
REPO="cdvankammen/OrcaSlicer"

echo "================================================"
echo "Monitoring GitHub Actions Build"
echo "Run ID: $RUN_ID"
echo "================================================"
echo ""

while true; do
    clear
    echo "========== BUILD STATUS =========="
    echo "Time: $(date '+%H:%M:%S')"
    echo ""

    # Get current status
    STATUS=$(gh run view $RUN_ID --repo $REPO --json status,conclusion --jq '{status: .status, conclusion: .conclusion}')
    echo "Overall Status: $STATUS"
    echo ""

    # Get job details
    echo "=== Job Status ==="
    gh run view $RUN_ID --repo $REPO --json jobs --jq '.jobs[] | "\(.name): \(.status) \(.conclusion)"'
    echo ""

    # Check if completed
    CONCLUSION=$(gh run view $RUN_ID --repo $REPO --json conclusion --jq -r '.conclusion')
    if [ "$CONCLUSION" != "null" ] && [ "$CONCLUSION" != "" ]; then
        echo ""
        echo "========================================="
        echo "BUILD COMPLETED: $CONCLUSION"
        echo "========================================="
        echo ""
        echo "View artifacts at:"
        echo "https://github.com/$REPO/actions/runs/$RUN_ID"
        break
    fi

    echo "Press Ctrl+C to stop monitoring"
    echo "Checking again in 2 minutes..."
    sleep 120
done
