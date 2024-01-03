#Requires -RunAsAdministrator

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
                Install-WindowsUpdate -AcceptAll -OutVariable InstallResult | Out-Host
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