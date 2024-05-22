#Requires -RunAsAdministrator

# Creates a link in the startup folder.
$Location = "$Env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Restart.bat"

$Script = 	"@echo off
REM Verifies if the script is running as admin.
net session >nul 2>&1
if %errorLevel% == 0 (
	goto Continue
) else (
	REM Restarts the script as admin.
	powershell -command `"Start-Process %~dpnx0 -Verb runas`"
)
powershell.exe -NoLogo -NoExit -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
"

if(!(Test-Path $Location)){
	$SCript | Out-File -FilePath $Location -Force
}

# Defines the manufacturer and exceptions for application removal.
Write-Verbose "Recovering computer information..."
$Manufacturer = (Get-ComputerInfo -Property CsManufacturer).CsManufacturer
$Exceptions = "Realtek|Intel|Microsoft|Windows"
Write-Verbose "$($Exceptions.Split("|").Count) exception(s) found:"
$Exceptions.Split("|") | ForEach-Object{Write-Verbose "`t * $_"}

Write-Verbose "Recovering installed applications..."
$BloatWareApps = Get-AppxPackage -AllUsers | Where-Object{$_.Name -notmatch $Exceptions -and $_.Name -match $Manufacturer}

Write-Host "Removing applications from the current profile..."
$BloatWareApps | Remove-AppxPackage -AllUsers | Out-Null
Write-Host "Removing applications from the template profile..."
Get-AppxProvisionedPackage -Online | Where-Object{$_.DisplayName -match $Manufacturer -and $_.DisplayName -notmatch $Exceptions} | Remove-AppxProvisionedPackage -Online

$RetryCount = 0
While($RetryCount -lt 3 -or $Retries){
	Write-Verbose "Recovering installed software..."
	$Soft = Get-WmiObject -Class Win32_Product | Where-Object{$_.Vendor -match $Manufacturer -and $_.Name -notmatch $Exceptions}
	Write-Host "Removing installed software..."
	$i = 0
	$iMax = $Soft.Count
	$Retries = @()
	foreach($SoftWare in $Soft){
		Write-Progress -Activity 'Uninstalling' -Status $Software.Name -PercentComplete (($i/$iMax)*100)
		$Temp = $SoftWare.Uninstall()
		if($Temp.ReturnValue){
			$Retries += $SoftWare
		}
		$i++
	}
	$RetryCount++
}

if(!$Soft){
	Remove-Item $Location
	Write-Host "No bloatware found."
}

Restart-Computer