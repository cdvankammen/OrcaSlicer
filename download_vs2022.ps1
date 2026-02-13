# Download VS 2022 Community installer
$url = "https://aka.ms/vs/17/release/vs_community.exe"
$output = "$env:TEMP\vs_community.exe"

Write-Host "Downloading VS 2022 Community installer..."
Invoke-WebRequest -Uri $url -OutFile $output
Write-Host "Download complete: $output"
