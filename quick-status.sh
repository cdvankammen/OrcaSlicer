#!/bin/bash
# Quick status check for GitHub Actions build

gh run view 22035189629 --repo cdvankammen/OrcaSlicer --json status,conclusion,createdAt | \
  jq '{
    status: .status,
    conclusion: .conclusion,
    runtime_minutes: ((now - (.createdAt | fromdateiso8601)) / 60 | floor)
  }'

echo ""
echo "Dependency Build Progress:"
gh api repos/cdvankammen/OrcaSlicer/actions/runs/22035189629/jobs | \
  jq '.jobs[] | select(.name | contains("Build Deps")) | {
    name: .name,
    progress: "\([.steps[] | select(.status == "completed")] | length)/\(.steps | length)",
    current_step: [.steps[] | select(.status == "in_progress") | .name][0]
  }'
