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
    [Switch]$ExternalBrowserAuthentication
)

$EULA_Accept=@{
    '7.0.1' = 1628510936
}