#Requires -RunAsAdministrator

param(
    [Switch]$Finish
)

<#| Computer Setup |#>

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
        Parameter = ''
        Path = "$Env:APPDATA\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Config.lnk"
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

# Verify if this is the first run.
$Flag = Get-Content -Path $FilePath | Where-Object{$_ -match '#UAC_Reboot#'}
if(!$Flag){
    '#UAC_Reboot#' | Out-File @LogParam
    Restart-Computer -Force
}

<#| Defining functions |#>

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

<#| Script Start |#>

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