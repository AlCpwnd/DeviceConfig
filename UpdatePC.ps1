param(
    [Parameter(Position=0)][ValidateSet('Start','Retry','Stop')]$Status
)

#Requires -RunAsAdministrator

if($Status -eq 'Start'){
    # Changes power options
    Write-Host "Configuring Power settings"
    & Powercfg /Change monitor-timeout-ac 60
    & Powercfg /Change monitor-timeout-dc 0
    & Powercfg /Change standby-timeout-ac 0
    & Powercfg /Change standby-timeout-dc 0

    # Disables UAC
    Write-Host "Disabling UAC"
    $RegistryItem = @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"
        Name = "EnableLUA"
    }
    if((Get-ItemProperty @RegistryItem).EnableLUA){
        Set-ItemProperty @RegistryItem -Value 0
    }

    # Verifies ExecutionPolicy
    if((Get-ExecutionPolicy) -ne "RemoteSigned"){
        Write-Host "Changing local execution policy"
        Set-ExecutionPolicy RemoteSigned -Force
    }

    # Installing the module if not already installed
    $ModuleCheck = Get-Module -Name PSWindowsUpdate -ListAvailable
    if(!$ModuleCheck){
        $PackageProviderCheck = Get-PackageProvider
        if($PackageProviderCheck.Name -notcontains "NuGet"){
            try{
                Write-Host "Installing package provider"
                Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
            }catch{
                Write-Host "Failed to install required Package Provider `"Nuget`"" -ForegroundColor Red
                Write-Host "Aborting script." -ForegroundColor Red
                Return
            }
        }
        try{
            Write-Host "Installing PSWindowsUpdate module"
            Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
        }catch{
            Write-Host "Failed to install module `"PSWindowsUpdate`"" -ForegroundColor Red
            Write-Host "Aborting script." -ForegroundColor Red
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
    Write-Host "Creating shortcuts"
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
    Write-Host "Recovering available updates"
    $AvailableUpdates = Get-WindowsUpdate
    if($AvailableUpdates){
        Write-Host "Installing updates"
        Install-WindowsUpdate -AcceptAll -AutoReboot -ErrorAction Stop
    }else{
        Write-Host "No new updates detected"
        Write-Host "Removing startup link"
        $LinkPath = "$Env:APPDATA\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\UpdatePC.lnk"
        Remove-Item $LinkPath -Force
        & cmd /c msg * "Device updates are done."
    }
}catch{
    & cmd /c msg * "Error running the updates. Aborting script."
}