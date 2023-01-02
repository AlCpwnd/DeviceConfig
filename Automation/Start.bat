@echo off
echo Administrative permissions required. Detecting permissions...

rem Verifies if the script is running as admin.
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.
) else (
    echo Failure: Current permissions inadequate.
    pause
    exit
)

