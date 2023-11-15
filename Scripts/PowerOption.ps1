param(
    [Parameter(ParameterSetName='File',Mandatory)][String]$Path,
    [Parameter(ParameterSetName='Manual')][Int]$MonitorSleepBattery,
    [Parameter(ParameterSetName='Manual')][Int]$ComputerSleepBattery,
    [Parameter(ParameterSetName='Manual')][Int]$MonitorSleepSector,
    [Parameter(ParameterSetName='Manual')][Int]$ComputerSleepSector
)

if($Path){
    $xml = Import-Clixml -Path $Path
}