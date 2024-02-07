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
        while($Continue -and $Tries -lt 4){
            Write-Host 'Checking updates.'
            Get-WindowsUpdate -OutVariable AvailableUpdates | Out-Host
            $UpdateTest = Compare-Object -ReferenceObject $InstalledUpdates -DifferenceObject $AvailableUpdates.Title -IncludeEqual
            if($UpdateTest.SideIndicator -contains '=>'){
                Write-Host 'Installing updates.'
                Install-WindowsUpdate -AcceptAll -IgnoreReboot -OutVariable InstallResult | Out-Host
                if($AutoReboot -and $InstallResult.ReboorRequired -contains 'True'){
                    Restart-Computer
                }
            }else{
                $Continue = $false
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
        <#
        .SYNOPSIS
        Installs Windows updates.

        .DESCRIPTION
        Downloads and installs available Windows updates.

        .PARAMETER AutoReboot
        Will restart the computer once the updates installed if one of them require it.

        .INPUTS
        None. You can't pipe objects to Update-Computer.

        .OUTPUTS
        Host prompts regarding the state of the update installation.
    #>
}

if($Auto){
    $Link = @{
        Parameter = '-Auto'
        Path = "$Env:APPDATA\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Config.lnk"
        Icon = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe,0"
    }
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
    }
    Update-Computer -AutoReboot
    Start-Sleep -Seconds 5
    Remove-Item $Link.Path
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