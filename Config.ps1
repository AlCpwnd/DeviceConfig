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

if($Status -eq 'Start'){
    # Alraedy done by BAT script
    # # Disables UAC if stil enabled
    # "Disabling UAC"
    # $RegistryItem = @{
    #     Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"
    #     Name = "EnableLUA"
    # }
    # if((Get-ItemProperty @RegistryItem).EnableLUA){
    #     Set-ItemProperty @RegistryItem -Value 0
    # }

    # Script is run with ByPass ExecutionPolicy
    # # Verifies ExecutionPolicy
    # if((Get-ExecutionPolicy) -ne "RemoteSigned"){
    #     "Changing local execution policy" | Out-File @LogParam
    #     Set-ExecutionPolicy RemoteSigned -Force
    # }


    Restart-Computer
}

if($Status -eq 'Stop'){
    # Removes shortcuts
    $Links = "$Env:PUBLIC\Desktop\Start.lnk","$Env:PUBLIC\Desktop\Retry.lnk","$Env:PUBLIC\Desktop\Stop.lnk","$Env:APPDATA\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\UpdatePC.lnk"
    $Links | ForEach-Object{Remove-Item $_ -Force}

    # Schedules removal of the script
    New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce -Name '!ScriptRemoval' -PropertyType 'String'  -Value "cmd /c DEL $PSCommandPath /F /Q"

    # Enables UAC
    $UAC = @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"
        Name = "EnableLUA"
        Value = 1
    }
    Set-ItemProperty @UAC

    Restart-Computer
}

# Updating device
try{
    Import-Module PSWindowsUpdate
    "Recovering available updates" | Out-File @LogParam
    $AvailableUpdates = Get-WindowsUpdate
    if($AvailableUpdates){
        "Installing updates" | Out-File @LogParam
        Install-WindowsUpdate -AcceptAll -AutoReboot -ErrorAction Stop
    }else{
        "No new updates detected" | Out-File @LogParam
        "Removing startup link" | Out-File @LogParam
        $LinkPath = "$Env:APPDATA\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\UpdatePC.lnk"
        Remove-Item $LinkPath -Force
        & cmd /c msg * "Device updates are done."
    }
}catch{
    & cmd /c msg * "Error running the updates. Aborting script."
}