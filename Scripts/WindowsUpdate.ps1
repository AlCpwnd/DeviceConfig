#Requires -RunAsAdministrator

param(
    [Switch]$Auto
)

function Set-Environment {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if(!(Get-PackageProvider -Name NuGet)){
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
        }
        if(!(Get-Module -Name PSWindowsUpdate -ListAvailable)){
            Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
        }
        if((Get-ExecutionPolicy) -eq 'Restricted'){
            Set-ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
        }
    }
    catch {
        Return $false
    }
    return $true
    <#
        .SYNOPSIS
        Prepares environment for the scripts.

        .DESCRIPTION
        Verifies the requires ExecutionPolicy, PackageProvider and Module are installed.

        .INPUTS
        None. You can't pipe objects to Set-Environment.

        .OUTPUTS
        A boolean, depending if the invironment could be modified and/or meets the requirements.

        .LINK
        Get-PackageProvider

        .LINK
        Install-PackageProvider

        .LINK
        Get-Module

        .LINK
        Install-Module

        .LINK
        Get-ExecutionPolicy

        .LINK
        Set-ExecutionPolicy
    #>
}

function Update-Computer {
    param(
        [Switch]$AutoReboot
    )
    if(!(Set-Environment)){
        throw 'Failed to configure environment.'
    }else{
        $Continue = $true
        $Tries = 1
        $InstalledUpdates = @()
        $RebootRequired = $false
        while($Continue -and $Tries -lt 4){
            Write-Host 'Checking updates.'
            Get-WindowsUpdate -IgnoreReboot -OutVariable AvailableUpdates | Out-Host
            if(!$AvailableUpdates){
                Write-Host 'No updates found.'
                break
            }
            $UpdateTest = Compare-Object -ReferenceObject $InstalledUpdates -DifferenceObject $AvailableUpdates.Title -IncludeEqual
            if($UpdateTest.SideIndicator -contains '=>'){
                Write-Host 'Installing updates.'
                Install-WindowsUpdate -AcceptAll -IgnoreReboot -OutVariable InstallResult | Out-Host
                if($InstallResult.ReboorRequired -contains 'True'){
                    $RebootRequired = $true
                    if($AutoReboot){
                        Restart-Computer
                    }
                }
            }else{
                $Continue = $false
                if($AutoReboot){
                    $RegKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\"
                    New-ItemProperty -Path $RegKey -Name "!WindowsUpdate" -Value 'cmd /c del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Restart.bat"'
                }
            }
            $InstalledUpdates += ($InstallResult | Where-Object{$_.Result -ne 'Failed'}).Title
            if($InstallResult.Result -contains 'Failed'){
                $Tries++
                if($Tries -eq 3){
                    Throw "Failed to installed updates 3 times."
                }
            }
        }
        Write-Host 'SuccessFully installed updates.'
    }
    If($RebootRequired){
        Write-Host 'You need to restart this computer in order to finalize the installation.' -ForegroundColor Yellow
    }

        <#
        .SYNOPSIS
        Installs Windows updates.

        .DESCRIPTION
        Downloads and installs available Windows updates.

        .PARAMETER AutoReboot
        Will restart the computer if an update requires it and will continue updating once 
        logged in.
        The shortcut will be automatically removed if no additionnal updates are found.

        .INPUTS
        None. You can't pipe objects to Update-Computer.

        .OUTPUTS
        Host prompts regarding the state of the update installation.
    #>
}

if($Auto){
    $Path = "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Restart.bat"
    $LinkTest = Test-Path $Path
    if(!$LinkTest){
        $Command = "net session >nul 2>&1
        if %errorLevel% == 0 (
            goto Continue
        ) else (
            REM Restarts the script as admin.
            powershell -command `"Start-Process %~dpnx0 -Verb runas`"
        )
        C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Auto"
        Set-Content -Path $Path -Value $Command
    }
    Update-Computer -AutoReboot
}Else{
    Update-Computer
}

<#
    .SYNOPSIS
    Installs the updates on the host computer.

    .DESCRIPTION
    Prepares the host computer and installs the PSWindowsUpdate module.
    Installs updates and restarts the computer if requested to.

    .PARAMETER Auto
    Will automatically restart the computer if the installed updates require it,
    and will create a shortcut within the startup folder in order to start the script
    again once rebooted.

    .INPUTS
    None. You can't pipe objects to WindowsUpdate.ps1.
#>