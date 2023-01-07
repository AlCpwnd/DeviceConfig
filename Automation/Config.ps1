param(
    [Parameter(Mandatory,ParameterSetName='Cfg')][String]$ConfigPath,
    [Parameter(Mandatory,ParameterSetName='Template')][Switch]$ExportConfig
)

#Requires -RunAsAdministrator

<#=== File export ===#>

if($ExportConfig){
    [Xml]$Cfg = '<Config Name="BaseConfig">
        <WindowsApps>
            <BloatWareRemoval>True</BloatWareRemoval>
            <AppInstallation Enabled="True">
                <FilePath></FilePath>
            </AppInstallation>
            <AppUpdate>True</AppUpdate>
        </WindowsApps>
        <PowerOptions Eabled="True">
            <DisableHybernate>True</DisableHybernate>
            <Battery>
                <DisplayTurnOff>30</DisplayTurnOff>
                <SleepTimer>60</SleepTimer>
            </Battery>
            <Plugged>
                <DisplayTurnOff>60</DisplayTurnOff>
                <SleepTimer>0</SleepTimer>
            </Plugged>
        </PowerOptions>
        <OfficeInstall>
            <UninstallPreloaded>True</UninstallPreloaded>
            <ConfigFile></ConfigFile>
        </OfficeInstall>
        <WindowsUpdates>True</WindowsUpdates>
    </Config>'
    $FilePath = "$PSScriptRoot\ConfigFile.xml"
    $Cfg | Out-File -FilePath $FilePath
    Write-Host "Config file exported to: $FIlePath"
    return
}


<#=== Functions ===#>

function Remove-BloatWare{
    param(
        [Parameter(Mandatory)][String]$Brand
    )
    switch ($Brand) {
        HP {
            $Apps = WMIC PRODUCT GET NAME /FORMAT:CSV | Convertfrom-Csv
            $Apps | Where-Object{$_.Name -like "HP*Security*"} | Foreach-Object{Invoke-Expression "cmd /c wmic product where `"Name like `'$($_.Name)`'`" call uninstall /nointeractive"}
            Get-AppxPackage -AllUsers | Where-Object{$_.Name -match "HP" -and $_.Name -notmatch "Realtek"} | Remove-AppxPackage -AllUsers
        }
        Default {Write-Host "Current brand isn't supported. No programs have been removed."}
    }
}

function Install-Update{
    $Module = Get-Module -Name PSWindowsUpdate -ListAvailable
    if($Module){
        $Updates = Get-WindowsUpdate
        if($Updates){
            $cfg.RebootCount++
            Install-WindowsUpdate -AcceptAll -AutoReboot
        }
    }else{
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module -Name PSWindowsUpdate
        Restart-Computer
    }
}

function show-info{
    param([Parameter(Mandatory,Position=0)][String]$Txt)
    $msg = "$(Get-Date -Format "[HH:MM:ss]"):$Txt"
    Write-Host $msg
    Add-Content -Path $Global:LogFile -Value $msg
}

function show-error{
    param([Parameter(Mandatory,Position=0)][String]$Txt)
    $Inverted = @{
        ForegroundColor = $Host.UI.RawUI.BackgroundColor
        BackgroundColor = $Host.UI.RawUI.ForegroundColor
    }
    $msg = "$(Get-Date -Format "[HH:MM:ss]"):[ERROR]:$Txt"
    Write-Host $msg @Inverted
    Add-Content -Path $Global:LogFile -Value $msg
}

#################################################



# Script : ######################################

## Verifies if the given configruation file is valid
try{
    [xml]$Config = Get-Content $ConfigPath -ErrorAction Stop
}catch{
    Write-Host "Invalid config file: $ConfigPath" @Inverted
    return
}


$Global:LogFile = "$PSScriptRoot\Logs_$Env:COMPUTERNAME.txt"

if(!(Test-Path $Global:LogFile)){
    $SystemInfo = Get-WMIObject -class Win32_ComputerSystem
    $Header = "| Date: $(Get-Date -Format dd/MM/yyyy)","|","| Config.ps1 log file.","|","| Serial N°: `t$((Get-WmiObject win32_bios).SerialNumber)","| Brand: `t$($SystemInfo.Brand)","| Model: `t$($SystemInfo.Model)","$("="*40)"
    $Header | Out-File $Global:LogFile
    show-info "Initiating script."
}

if($Config.Config.WindowsApps.BloatWareRemoval){
    Remove-BloatWare $SystemInfo.Brand
}

#################################################