#Requires -RunAsAdministrator

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
    Restart-Computer
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
$LinkPath = "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\UpdatePC.lnk"
$LinkTest = Test-Path $LinkPath
if(!$LinkTest){
    Write-Host "Creating the startup shortcut"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($LinkPath)
    $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = "-NoLogo -NoExit -NoProfile -File $PSCommandPath"
    $Shortcut.Save()
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
        Write-Host "Removing startup link"
        Remove-Item $LinkPath -Force
        & cmd /c msg * "Device updates are done."
    }
}catch{
    & cmd /c msg * "Error running the updates. Aborting script."
}