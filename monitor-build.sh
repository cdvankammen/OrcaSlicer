#!/bin/bash
# Monitor GitHub Actions Build Status

echo "================================================"
echo "Monitoring GitHub Actions Build"
echo "================================================"
echo ""

REPO="cdvankammen/OrcaSlicer"
WORKFLOW="build-custom-features.yml"

echo "Checking for running builds..."
echo ""

while true; do
    # Get latest run
    RUN_INFO=$(gh run list --repo $REPO --workflow=$WORKFLOW --limit 1 --json status,conclusion,databaseId,displayTitle,createdAt 2>&1)

    if [ $? -eq 0 ]; then
        STATUS=$(echo "$RUN_INFO" | jq -r '.[0].status')
        CONCLUSION=$(echo "$RUN_INFO" | jq -r '.[0].conclusion')
        RUN_ID=$(echo "$RUN_INFO" | jq -r '.[0].databaseId')
        TITLE=$(echo "$RUN_INFO" | jq -r '.[0].displayTitle')
        CREATED=$(echo "$RUN_INFO" | jq -r '.[0].createdAt')

        echo "[$(date '+%H:%M:%S')] Status: $STATUS | Conclusion: $CONCLUSION"

        if [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ]; then
            echo "  ✓ Build is running! Run ID: $RUN_ID"
            echo "  Title: $TITLE"
            echo "  View: https://github.com/$REPO/actions/runs/$RUN_ID"
            echo ""
            echo "Build detected! Continuing to monitor..."
            echo ""

            # Monitor until complete
            while true; do
                RUN_STATUS=$(gh run view $RUN_ID --repo $REPO --json status,conclusion 2>&1)
                CURRENT_STATUS=$(echo "$RUN_STATUS" | jq -r '.status')
                CURRENT_CONCLUSION=$(echo "$RUN_STATUS" | jq -r '.conclusion')

                echo "[$(date '+%H:%M:%S')] Build status: $CURRENT_STATUS"

                if [ "$CURRENT_STATUS" = "completed" ]; then
                    echo ""
                    echo "================================================"
                    if [ "$CURRENT_CONCLUSION" = "success" ]; then
                        echo "BUILD COMPLETED SUCCESSFULLY! ✓"
                    else
                        echo "BUILD FAILED: $CURRENT_CONCLUSION"
                    fi
                    echo "================================================"
                    echo ""
                    echo "View results: https://github.com/$REPO/actions/runs/$RUN_ID"
                    exit 0
                fi

                sleep 30  # Check every 30 seconds
            done
        elif [ "$CONCLUSION" = "success" ]; then
            echo "  ✓ Latest build succeeded!"
            echo "  Download artifacts: https://github.com/$REPO/actions/runs/$RUN_ID"
            exit 0
        fi
    fi

    echo "  No active builds yet. Waiting..."
    echo "  Trigger build at: https://github.com/$REPO/actions/workflows/$WORKFLOW"
    echo ""

    sleep 15  # Check every 15 seconds
done
