#Requires -RunAsAdministrator

# Verifies ExecutionPolicy
if((Get-ExecutionPolicy) -ne "RemoteSigned"){
    Set-ExecutionPolicy RemoteSigned -Force
}


# Installing the module if not already installed.
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

$LinkPath = "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\UpdatePC.lnk"
$LinkTest = Test-Path $LinkPath
if(!$LinkTest){
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($LinkPath)
    $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = "-NoLogo -NoExit -NoProfile -WindowStyle Maximised -File $PSCommandPath"
    $Shortcut.Save()
}