# Monitor OrcaSlicer build progress
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OrcaSlicer Build Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$logFile = "J:\github orca\OrcaSlicer\build_progress.log"
$lastSize = 0

Write-Host "Waiting for build to start..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
Write-Host ""

while ($true) {
    if (Test-Path $logFile) {
        $currentSize = (Get-Item $logFile).Length

        if ($currentSize -gt $lastSize) {
            $content = Get-Content $logFile -Tail 50

            # Show interesting lines
            $content | Where-Object {
                $_ -match "building|Building|configuring|Configuring|\[.*%\]|error|Error|warning|Warning|Successfully|FAILED|completed"
            } | ForEach-Object {
                if ($_ -match "error|Error|FAILED") {
                    Write-Host $_ -ForegroundColor Red
                } elseif ($_ -match "warning|Warning") {
                    Write-Host $_ -ForegroundColor Yellow
                } elseif ($_ -match "Successfully|completed|OK") {
                    Write-Host $_ -ForegroundColor Green
                } else {
                    Write-Host $_ -ForegroundColor White
                }
            }

            $lastSize = $currentSize
        }
    }

    Start-Sleep -Seconds 5
}
