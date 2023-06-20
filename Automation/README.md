# Device configuration automation
These script are mean to automte various steps described in the home directory of this repository by use of scripts and a config XML file.

## Config.ps1
This script will be the one doing most of the configurations.

### Parameters

- ConfigPath: Path towards the config XML file you want to use for the installation.
- ExportConfig: Switch allowing you to export a default template of the XML config file.

## Update Installation
If you wish to quickly see the updates that are to be installed on the current device, run the following command within a ran as admin PowerShell windows:
```ps
Install-PackageProvider -Name NuGet -Force; Install-Module -Name PSWindowsUpdate -Force; Set-ExecutionPolicy RemoteSigned -Force; ipmo PSWindowsUpdate; if(Get-WindowsUpdate){Install-WindowsUpdate -AcceptAll}
```
It will request you restart the device if required.