#Requires -RunAsAdministrator

# Verifies the current execution policy.
if((Get-ExecutionPolicy) -eq 'Restricted'){
    Set-ExecutionPolicy RemoteSigned -Force
}

# Verifies the package providers.
if(!(Get-PackageProvider -Name 'Nuget')){
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name 'NuGet' -Force
}

# Verifies the installed modules
if(!(Get-Module -Name 'PSWindowsUpdate' -ListAvailable)){
    Install-Module -Name 'PSWindowsUpdate' -Force
}

# Verifies if updates are available
Get-WindowsUpdate -OutVariable UpdateTest | Out-Host

# Proposed to install available updates
if($UpdateTest){
    switch (Read-Host -Prompt 'Do you wish to install the updates now? [Y / N] (Default is N)') {
        {$_ -match 'y'} {Install-WindowsUpdate -AcceptAll}
        Default {}
    }
}