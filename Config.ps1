#Requires -RunAsAdministrator

param(
    [Switch]$Finish
)

$Date = Get-Date -Format yyyyMMdd

$LogParam = @{
    FilePath = "$PSScriptRoot\$Env:COMPUTERNAME`_$Date.txt"
    Append = $true
}

# Generates the logfile at the script root if it doesn't exist.
if(!(Test-Path $FilePath)){
    $Date = Get-Date -Format 'dd/MM/yyyy hh:MM'
    "[ Script start: $Date ]" | Out-File @LogParam
}

# Generating shortcuts.
$Links = @{
        Parameter = '-Finish'
        Path = "$Env:PUBLIC\Desktop\Finish.lnk"
        Icon = "%windir%\system32\cleanmgr.exe,0"
    },@{
        Path = "$Env:APPDATA\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Config.lnk"
        Parameter = ''
        Icon = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe,0"
    }
"Verifying shortcuts" | Out-File @LogParam
foreach($Link in $Links){
    $LinkTest = Test-Path $Link.Path
    if(!$LinkTest){
        $Command = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoExit -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $Parameter"
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($Link.Path)
        $Shortcut.TargetPath = $Command
        if(Test-Path $env:SystemRoot\System32\imageres.dll){
            $Shortcut.IconLocation = $Link.Icon
        }
        $Shortcut.Save()
        "Link created: $($Link.Path)" | Out-File @LogParam
    }
}
