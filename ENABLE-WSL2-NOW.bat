@echo off
echo ================================================
echo Enabling WSL2 Features
echo ================================================
echo.
echo This will enable WSL2 and restart your computer.
echo.
pause

REM Enable WSL
echo Enabling Windows Subsystem for Linux...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

REM Enable Virtual Machine Platform
echo.
echo Enabling Virtual Machine Platform...
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

echo.
echo ================================================
echo SUCCESS! Features enabled.
echo ================================================
echo.
echo Your computer will restart in 60 seconds.
echo Save any open work!
echo.
pause

shutdown /r /t 60
