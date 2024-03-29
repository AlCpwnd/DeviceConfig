# FortiClientConfig.md

## Synopsis
Configures the FortiClient for a device.

## Syntax
```
FortiClientConfig.ps1 -Name <String> [-Description <String>] -RemoteGateway <Array> [-Port <Int32>] -SingleSignOn [-ExternalBrowserAuthentication] 
[-AcceptEULA] [-Version <String>] [<CommonParameters>]
```
```
FortiClientConfig.ps1 -Name <String> [-Description <String>] -RemoteGateway <Array> [-Port <Int32>] [-AcceptEULA] [-Version <String>] [<CommonParameters>]
```

## Description
Will configure a FortiClient VPN connection with the given parameters.

## Parameters

### -Name
Name of you want to give the connection.
```
Type: String
Parameter Sets: (All)

Required: true
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```

### -Description
Description you want to give the connection.
```
Type: String
Parameter Sets: (All)

Required: false
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```

### -RemoteGateway
Gateway(s) you want to configure within the VPN connection.
```
Type: Array
Parameter Sets: (All)

Required: true
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```

### -Port
Port you want to use for the VPN connection. If not mentionned, the default port 443 is used.
```
Type: Int32
Parameter Sets: (All)

Required: false
Position: named
Default value: 0
Accept pipeline: false
Accept wildcard characters: false
```

### -SingleSignOn
Enables Single Sign on for the VPN connection.
```
Type: SwitchParameter
Parameter Sets: (All)

Required: true
Position: named
Default value: False
Accept pipeline: false
Accept wildcard characters: false
```

### -ExternalBrowserAuthentication
Uses external browser authentication when using single sign on.
```
Type: SwitchParameter
Parameter Sets: (All)

Required: false
Position: named
Default value: False
Accept pipeline: false
Accept wildcard characters: false
```

### -AcceptEULA
Will auto-accept the EULA prompt on first start for all existing users.
```
Type: SwitchParameter
Parameter Sets: (All)

Required: false
Position: named
Default value: False
Accept pipeline: false
Accept wildcard characters: false
```

### -Version
Version of the client you want to configure. If not given, it will register the EULA for all known versions.
```
Type: String
Parameter Sets: (All)

Required: false
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```
