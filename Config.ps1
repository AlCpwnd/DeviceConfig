#Requires -RunAsAdministrator

param(
    [Switch]$Finish
)

#-------------------------------------------------------------------------------------------------#
# Environment Prep :

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

# Preparing reboot script.
$Path = "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Restart.bat"
$LinkTest = Test-Path $Path
if(!$LinkTest){
    $Command = "net session >nul 2>&1
    if %errorLevel% == 0 (
        goto Continue
    ) else (
        powershell -command `"Start-Process %~dpnx0 -Verb runas`"
    )
    C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Auto"
    Set-Content -Path $Path -Value $Command
}

# Preparing Ending script.
$Path = "$env:PUBLIC\Desktop\Finish.bat"
$LinkTest = Test-Path $Path
if(!$LinkTest){
    $Command = "net session >nul 2>&1
    if %errorLevel% == 0 (
        goto Continue
    ) else (
        powershell -command `"Start-Process %~dpnx0 -Verb runas`"
    )
    C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Finish"
    Set-Content -Path $Path -Value $Command
}

# Verify if this is the first run.
$Flag = Get-Content -Path $FilePath | Where-Object{$_ -match '#UAC_Reboot#'}
if(!$Flag){
    # Restart the computer in order to apply the UAC changes.
    '#UAC_Reboot#' | Out-File @LogParam
    Restart-Computer -Force
}

#-------------------------------------------------------------------------------------------------#
# Defining Functions :

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
        while($Continue -and $Tries -lt 4){
            Write-Host 'Checking updates.'
            Get-WindowsUpdate -OutVariable UpdateTest | Out-Host
            if($UpdateTest.Status -contains '-------'){
                Write-Host 'Installing updates.'
                Install-WindowsUpdate -AcceptAll -IgnoreReboot -OutVariable InstallResult | Out-Host
                if($AutoReboot -and $InstallResult.ReboorRequired -contains 'True'){
                    Restart-Computer
                }
            }else{
                $Continue = $false
            }
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

#-------------------------------------------------------------------------------------------------#
# Script :

# Future use facilitation
## Numlock at boot
$RKey = Get-ItemProperty 'registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard\'
if($RKey.InitialKeyboardIndicators -ne 2147483650){
    Set-ItemProperty 'registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard\' -Name 'InitialKeyboardIndicators' -Value 2147483650
}

# Update installation
$Flag = Get-Content $FilePath | Where-Object{$_ -match '#Windows_Update_Skip#|#Windows_Update_Done#'}
if(!$Flag){t
    try{
        Update-Computer -AutoReboot
    }catch{
        'Failed to install Windows updates.','#Windows_Update_Skip#' | Out-File @LogParam
    }
}

#-------------------------------------------------------------------------------------------------#
# End & Cleanup :

if($Finish){
    # Copies the log file back to the original start location.
    $OriginFile = 'C:\Setup\ScriptOrigin.txt'
    if(Test-Path -Path $OriginFile){
        try{
            $Origin = Get-Content -Path $OriginFile
            # Skips the log copy if the origin is the same device.
            if($Origin -notmatch 'C:'){
                Copy-Item -Path $LogParam.FilePath -Destination $Origin -ErrorAction Stop
            }
        }catch{
            Write-Host "Failed to copy logs back to : $Origin"
        }
    }

    # Re-enables UAC.
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -Value 1
}