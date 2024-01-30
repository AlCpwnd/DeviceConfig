# Scripts

This directory contains the individual scripts used to configure the various functions.

## PowerOption.ps1

> :warning: Not finished.

Configures the windows power options according to the given parameter or using the linked xml template.

---

## WindowsUpdate.ps1

> :information_source: Uses the module [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate/2.2.0.3).

> :warning: Still needs to be tested.

### Synopsis

Installs the updates on the host computer.

### Syntax

```
WindowsUpdate.ps1 [-Auto] [<CommonParameters>]
```

### Description

Prepares the host computer and installs the PSWindowsUpdate module.
Installs updates and restarts the computer if requested to.

### Parameters

#### -Auto

Will automatically restart the computer if the installed updates require it,
and will create a shortcut within the startup folder in order to start the script
again once rebooted.

```
Type: SwitchParameter
Parameter Sets: (All)

Required: false
Position: named
Default value: False
Accept pipeline: false
Accept wildcard characters: false
```
