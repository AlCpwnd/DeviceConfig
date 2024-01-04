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
        $Parameters = @{
            AcceptAll = $true
            OutVariable = 'InstallResult'
        }
        if($AutoReboot){
            $Parameters | Add-Member -MemberType NoteProperty -Name AutoReboot -Value $true
        }
        $Continue = $true
        $Tries = 1
        while($Continue -and $Tries -lt 4){
            Write-Host 'Checking updates.'
            Get-WindowsUpdate -OutVariable UpdateTest | Out-Host
            if($UpdateTest.Status -contains '-------'){
                Write-Host 'Installing updates.'
                Install-WindowsUpdate @Parameters | Out-Host
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
}

<#| Script Start |#>

# Update installation
$Flag = Get-Content $FilePath | Where-Object{$_ -match '#Windows_Update_Skip#|#Windows_Update_Done#'}
if(!$Flag){t
    try{
        Update-Computer -AutoReboot
    }catch{
        'Failed to install Windows updates.','#Windows_Update_Skip#' | Out-File @LogParam
    }
}