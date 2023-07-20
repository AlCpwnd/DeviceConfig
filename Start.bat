@echo off
echo Administrative permissions required. Detecting permissions...

rem Verifies if the script is running as admin.
net session >nul 2>&1
if %errorLevel% == 0 (
    goto Continue
) else (
    powershell -command "Start-Process Start.bat -Verb runas"
)

:Continue
rem Moves the contents of the USB to a setup folder.
pushd %~dp0
MKDIR C:\Setup
COPY .\* C:\Setup

rem Disables UAC for future runs.
reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

rem Runs the followup PowerShell script.
powershell -Command