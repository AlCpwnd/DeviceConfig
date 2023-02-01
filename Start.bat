@echo off
echo Administrative permissions required. Detecting permissions...

SET PSScript = ".\UpdatePC.ps1"

rem Verifies if the script is running as admin.
net session >nul 2>&1
if %errorLevel% == 0 (
    goto Continue
) else (
    powershell -command "Start-Process Start.bat -Verb runas"
)

:Continue
IF NOT EXIST %PSScript% powershell -NoLogo -NoExit -NoProfile -WindowStyle Maximized -ExecutionPolicy ByPass -Code {Invoke-WebRequest -Uri "https://raw.githubusercontent.com/AlCpwnd/DeviceConfig/WindowsUpdateIntergration/UpdatePC.ps1" -UseBasicParsing -OutFile %PSScript%;& UpdatePC.ps1}
pause