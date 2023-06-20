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
echo Execution upgrade successfull