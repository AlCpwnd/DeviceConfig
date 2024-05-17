#Requires -RunAsAdministrator

Write-Host "Scanning image"
Repair-WindowsImage -Online -ScanHealth -OutVariable ScanResult

if($ScanResult.ImageHealthState -eq 'Repairable'){
    Write-Host "Issues found. Attempting repair."
    Repair-WindowsImage -Online -RestoreHealth -OutVariable RepairResult
}else{
    Write-Host "No issues found."
}
