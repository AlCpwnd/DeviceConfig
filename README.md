# Device Configuration
> PowerShell ran as admin.

Summary of commands used to configure a machine.

---

## Bloatware removal

### HP
Removes all pre-installed HP Security components and uninstalls pre-installed HP applications. (With the exception of audio drivers)
```ps
$Apps = WMIC PRODUCT GET NAME /FORMAT:CSV | Convertfrom-Csv
$Apps | Where-Object{$_.Name -like "HP*Security*"} | Foreach-Object{Invoke-Expression "cmd /c wmic product where `"Name like `'$($_.Name)`'`" call uninstall /nointeractive"}
Get-AppxPackage -AllUsers | Where-Object{$_.Name -match "HP" -and $_.Name -notmatch "Realtek"} | Remove-AppxPackage -AllUsers
```

---

## Application installation
> This is assuming [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) is installed on the device you're configuring.

Will install all application listed in [Install.txt](Install.txt).
```ps
(Invoke-WebRequest -Uri https://raw.githubusercontent.com/AlCpwnd/DeviceConfig/main/Install.txt -UseBasicParsing).Content.Split() | ForEach-Object{winget install -e --id $_ -h}
```

### Office Deployment
> Assuming you're using [Office Deployment Tool](https://www.microsoft.com/en-us/download/details.aspx?id=49117).
#### Office Removal
Will uninstall all installed Office application from the device.
```ps
winget install -e --id Microsoft.OfficeDeploymentTool -h
Invoke-WebRequest -Uri https://raw.githubusercontent.com/AlCpwnd/DeviceConfig/main/OdtUninstall.xml -OutFile "C:\Program Files\OfficeDeploymentTool\Uninstall.xml" -UseBasicParsing
& 'C:\Program Files\OfficeDeploymentTool\setup.exe' /Configure 'C:\Program Files\OfficeDeploymentTool\Uninstall.xml'
```

#### Office Installation
> `<Path>` is referring to your own [Office config file](https://config.office.com/deploymentsettings).
```ps
winget install -e --id Microsoft.OfficeDeploymentTool -h
& 'C:\Program Files\OfficeDeploymentTool\setup.exe' /Download <Path>
& 'C:\Program Files\OfficeDeploymentTool\setup.exe' /Configure <Path>
```

The following commands will install the following languages: French-France, English-UK, German-Germany, Dutch-Netherlands
The full configuration can be found in [Default_UK_FR_NL_DE.xml](Default_UK_FR_NL_DE.xml).
```ps
Invoke-WebRequest -Uri https://raw.githubusercontent.com/AlCpwnd/DeviceConfig/main/Default_UK_FR_NL_DE.xml -OutFile "C:\Program Files\OfficeDeploymentTool\Default.xml"
& 'C:\Program Files\OfficeDeploymentTool\setup.exe' /Download 'C:\Program Files\OfficeDeploymentTool\Default.xml'
& 'C:\Program Files\OfficeDeploymentTool\setup.exe' /Configure 'C:\Program Files\OfficeDeploymentTool\Default.xml'
```