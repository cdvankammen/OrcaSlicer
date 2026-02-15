# Enable WSL2 - Run as Administrator
# Right-click this file and select "Run with PowerShell"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Enabling WSL2 Features..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click this file and select 'Run with PowerShell'" -ForegroundColor Yellow
    Write-Host "Or open PowerShell as Admin and run:" -ForegroundColor Yellow
    Write-Host "  cd 'J:\github orca\OrcaSlicer'" -ForegroundColor White
    Write-Host "  .\enable-wsl2.ps1" -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

Write-Host "Running as Administrator - OK" -ForegroundColor Green
Write-Host ""

# Enable WSL
Write-Host "Enabling Windows Subsystem for Linux..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
Write-Host ""

# Enable Virtual Machine Platform
Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
Write-Host ""

Write-Host "================================================" -ForegroundColor Green
Write-Host "SUCCESS! Features enabled." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Your computer must restart for changes to take effect." -ForegroundColor Yellow
Write-Host ""

$restart = Read-Host "Restart now? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Write-Host ""
    Write-Host "Restarting in 10 seconds..." -ForegroundColor Yellow
    Write-Host "Save any open work!" -ForegroundColor Red
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host ""
    Write-Host "Please restart your computer manually for changes to take effect." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After restart, run: wsl --distribution Ubuntu" -ForegroundColor Cyan
}

Write-Host ""
pause
