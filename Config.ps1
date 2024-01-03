#Requires -RunAsAdministrator

$LogOutputParam = @{
    FilePath = "$PSScriptRoot\$Env:COMPUTERNAME.txt"
    Append = $true
}

if($Status -eq 'Start'){
    # Changes power options
    "Configuring Power settings" | Out-File @LogOutputParam
    & Powercfg /Change monitor-timeout-ac 60
    & Powercfg /Change monitor-timeout-dc 0
    & Powercfg /Change standby-timeout-ac 0
    & Powercfg /Change standby-timeout-dc 0

    # Disables UAC
    "Disabling UAC"
    $RegistryItem = @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"
        Name = "EnableLUA"
    }
    if((Get-ItemProperty @RegistryItem).EnableLUA){
        Set-ItemProperty @RegistryItem -Value 0
    }

    # Verifies ExecutionPolicy
    if((Get-ExecutionPolicy) -ne "RemoteSigned"){
        "Changing local execution policy" | Out-File @LogOutputParam
        Set-ExecutionPolicy RemoteSigned -Force
    }

    # Installing the module if not already installed
    $ModuleCheck = Get-Module -Name PSWindowsUpdate -ListAvailable
    if(!$ModuleCheck){
        $PackageProviderCheck = Get-PackageProvider
        if($PackageProviderCheck.Name -notcontains "NuGet"){
            try{
                "Installing package provider" | Out-File @LogOutputParam
                Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
            }catch{
                "Failed to install required Package Provider `"Nuget`"" | Out-File @LogOutputParam
                "Aborting script." | Out-File @LogOutputParam
                Return
            }
        }
        try{
            "Installing PSWindowsUpdate module" | Out-File @LogOutputParam
            Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
        }catch{
            "Failed to install module `"PSWindowsUpdate`"" | Out-File @LogOutputParam
            "Aborting script." | Out-File @LogOutputParam
            return
        }
    }

    # Generating post restart script run
    $Links = @{
            Path = "$Env:PUBLIC\Desktop\Start.lnk"
            Parameters = "Start"
            Icon = "imageres.dll,232"
        },@{
            Path = "$Env:PUBLIC\Desktop\Retry.lnk"
            Parameters = "Retry"
            Icon = "imageres.dll,230"
        },@{
            Path = "$Env:PUBLIC\Desktop\Stop.lnk"
            Parameters = "Stop"
            Icon = "imageres.dll,229"
        },@{
            Path = "$Env:APPDATA\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\UpdatePC.lnk"
            Parameters = "Retry"
            Icon = "imageres.dll,233"
        }
    "Creating shortcuts"
    foreach($Link in $Links){
        $LinkTest = Test-Path $Link.Path
        if(!$LinkTest){
            $Command = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoExit -NoProfile -File $PSCommandPath $($Link.Parameter)"
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($Link.Path)
            $Shortcut.TargetPath = $Command
            if(Test-Path $env:SystemRoot\System32\imageres.dll){
                $Shortcut.IconLocation = $Link.Icon
            }
            $Shortcut.Save()
        }
    }

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
    "Recovering available updates" | Out-File @LogOutputParam
    $AvailableUpdates = Get-WindowsUpdate
    if($AvailableUpdates){
        "Installing updates" | Out-File @LogOutputParam
        Install-WindowsUpdate -AcceptAll -AutoReboot -ErrorAction Stop
    }else{
        "No new updates detected" | Out-File @LogOutputParam
        "Removing startup link" | Out-File @LogOutputParam
        $LinkPath = "$Env:APPDATA\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\UpdatePC.lnk"
        Remove-Item $LinkPath -Force
        & cmd /c msg * "Device updates are done."
    }
}catch{
    & cmd /c msg * "Error running the updates. Aborting script."
}