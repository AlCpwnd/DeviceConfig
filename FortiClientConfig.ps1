param(
    [Parameter(ParameterSetName='Manual',Mandatory)]
    [Parameter(ParameterSetName='SSO',Mandatory)]
    [String]$Name,

    [Parameter(ParameterSetName='Manual')]
    [Parameter(ParameterSetName='SSO')]
    [String]$Description,

    [Parameter(ParameterSetName='Manual',Mandatory)]
    [Parameter(ParameterSetName='SSO',Mandatory)]
    [Array]$RemoteGateway,

    [Parameter(ParameterSetName='Manual')]
    [Parameter(ParameterSetName='SSO')]
    [Int32]$Port,

    [Parameter(ParameterSetName='SSO',Mandatory)]
    [Switch]$SingleSignOn,

    [Parameter(ParameterSetName='SSO')]
    [Switch]$ExternalBrowserAuthentication,

    [Parameter(ParameterSetName='Manual')]
    [Parameter(ParameterSetName='SSO')]
    [Swicth]$AcceptEULA,

    [Parameter(ParameterSetName='Manual')]
    [Parameter(ParameterSetName='SSO')]
    [String]$Version
)

#Requires -RunAsAdministrator

# Creates the registry key for the configuration
$ConfigKey = "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$Name"
if(!(Test-Path $ConfigKey)){
    New-Item $ConfigKey -Force
}



if($AcceptEULA){
    if($Verion){
        if($Verion -notmatch '\d\.\d\.\d\.\d{4}'){
            throw "Please use the complete version number. ex: 7.0.2.0090"
        }
    }
    # Creating HKEY_USERS access
    New-PSDrive -Name HKU -Root HKEY_USERS -PSProvider Registry
    # Recovering existing user profiles
    $UserIDs = (Get-ChildItem HKU:\).Name | Where-Object{$_ -match 'S-\d-\d-\d{2}-.*'}
    $EULA_Accept=@{
        '6.2.0.0780' = 1555407840
        '7.0.0.0029' = 1619473136
        '7.0.1' = 1628510936
        '7.0.2.0090' = 1635150094
        '7.0.7.0345' = 1661945782
        '7.0.8.0427' = 1678887314
    }
    $Key = '\Software\Fortinet\FortiClient\FA_UI\vpn-'
    foreach($UserId in $UserIDs){
        if($Verion){
            if($EULA_Accept.Keys -contains $Verion){
                New-Item "HKU:$Key$Verion" -Force
                New-ItemProperty "$Key$Verion" -Name "installed" -PropertyType DWORD -Value $EULA_Accept[$Version]   
            }else{
                Write-Error "Unsupported version: $Version" -Category "AcceptEULA"
            }
        }else{
            foreach($SWVersion in $EULA_Accept.Keys){
                New-Item "$Key$Verion" -Force
                New-ItemProperty "$Key$Verion" -Name "installed" -PropertyType DWORD -Value $EULA_Accept[$Version]
            }
        }
    }
    
}

<#
    .SYNOPSIS
    Configures the FortiClient for a device.

    .DESCRIPTION
    Will configure a FortiClient VPN connection with the given parameters.

    .PARAMETER Name
    Name of you want to give the connection.

    .PARAMETER Description
    Description you want to give the connection.
    
    .PARAMETER RemoteGateway
    Gateway(s) you want to configure within the VPN connection.
    
    .PARAMETER Port
    Port you want to use for the VPN connection. If not mentionned, the default port 443 is used.
    
    .PARAMETER SingleSignOn
    Enables Single Sign on for the VPN connection.
    
    .PARAMETER ExternalBrowserAuthentication
    Uses external browser authentication when using single sign on.
    
    .PARAMETER AcceptEULA
    Will auto-accept the EULA prompt on first start for all existing users.

    .PARAMETER Version
    Version of the client you want to configure. If not given, it will register the EULA for all known versions.
#>