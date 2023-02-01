#Requires -RunAsAdministrator

# Disables UAC
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
    Set-ExecutionPolicy RemoteSigned -Force
}

# Installing the module if not already installed
$ModuleCheck = Get-Module -Name PSWindowsUpdate -ListAvailable
if(!$ModuleCheck){
    $PackageProviderCheck = Get-PackageProvider -Name NuGet
    if($PackageProviderCheck){
        try{
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
        }catch{
            Write-Host "Failed to install required Package Provider `"Nuget`"" -ForegroundColor Red
            Write-Host "Aborting script." -ForegroundColor Red
            Return
        }
    }
    try{
        Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
        Import-Module PSWindowsUpdate
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
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($LinkPath)
    $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = "-NoLogo -NoExit -NoProfile -WindowStyle Maximized -File $PSCommandPath"
    $Shortcut.Save()
}

# Updating device
try{
    Import-Module PSWindowsUpdate
    $AvailableUpdates = Get-WindowsUpdate
    if($AvailableUpdates){
        Install-WindowsUpdate -AcceptAll -AutoReboot -ErrorAction Stop
    }else{
        Remove-Item $LinkPath -Force
        & cmd /c msg * "Device updates are done."
    }
}catch{
    & cmd /c msg * "Error running the updates. Aborting script."
}