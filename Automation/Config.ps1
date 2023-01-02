param(
    [String]$ConfigPath
)

#Requires -RunAsAdministrator

# Defining Variables : ##########################

## Device Brand
$Brand = (Get-WMIObject -class Win32_ComputerSystem).Manufacturer

## Configuration File Path
if(!$ConfigPath){$ConfigPath = ".\Config.txt"}

#################################################



# Funtions : ####################################

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

#################################################



# Script : ######################################

## Configuration Preperation
if(!(Test-Path -Path $ConfigPath)){
    $Config = "#==========================#",
        "#Script Configuration File:#",
        "#==========================#",
        "BloatwareRemoval=TRUE"
        "Update=True",
        "UpdateCount=0"
        "OfficeCleanup=True",
        "OfficeInstall=True",
        "OfficeConfig=",
        "Status=Start"
    $Config | Out-File -FilePath $ConfigPath
}else{
    $Config = Get-Content -Path $ConfigPath -
}

$cfg = [PSCustomObject]@{
    Update = ''
    RebootCount = 0
    OfficeCleanup = ''
    OfficeInstall = ''
    OfficeConfig = ''
    Status = ''
}

foreach($Entry in $Config){
    if($Entry -match "#"){
        Continue
    }
    $Temp = $Entry.Split("=")
    $cfg.$Temp[0] = $Temp[1]
}


#################################################