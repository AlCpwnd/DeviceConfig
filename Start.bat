@echo off
echo Administrative permissions required. Detecting permissions...

REM Verifies if the script is running as admin.
net session >nul 2>&1
if %errorLevel% == 0 (
    goto Continue
) else (
    REM Restarts the script as admin.
    powershell -command "Start-Process %~dpnx0 -Verb runas"
)

:Continue
REM Moves the contents of the USB to a setup folder.
pushd %~dp0
REM Creates the destination folder if it doesn't exist.
IF NOT EXIST C:\Setup MKDIR C:\Setup
COPY .\* C:\Setup

REM Documents the origin of the files.
%~dp0 > C:\Setup\ScriptOrigin.txt

REM Disables UAC for future runs.
REM This will be re-enabled at the end of the scripts.
reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

REM Runs the followup PowerShell script.
PowerShell -File "C:\Setup\Config.ps1" -ExecutionPolicy ByPass
