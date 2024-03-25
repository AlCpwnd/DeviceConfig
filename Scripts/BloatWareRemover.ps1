#Requires -RunAsAdministrator

# Creates a link in the startup folder.
$Link = @{
	Parameter = ''
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
	Write-Verbose "Link Created"
}

# Defins the manufacturer and exceptions for application removal.
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

Write-Verbose "Recovering installed software..."
$Soft = Get-WmiObject -Class Win32_Product | Where-Object{$_.Vendor -match $Manufacturer -and $_.Name -notmatch $Exceptions}
Write-Host "Removing installed software..."
$i = 0
$iMax = $Soft.Count
foreach($SoftWare in $Soft){
	Write-Progress -Activity 'Uninstalling' -Status $Software.Name -PercentComplete (($i/$iMax)*100)
	$SoftWare.Uninstall()
	$i++
}

if(!$Soft){
	Remove-Item $Link.Path
	Write-Host "No bloatware found."
}

Restart-Computer