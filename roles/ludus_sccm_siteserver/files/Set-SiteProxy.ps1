param([string]$SiteCode, [string]$SiteServer, [string]$ProxyName, [int]$ProxyPort, [string]$ProxyAccount)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
Import-Module ConfigurationManager -ErrorAction Stop
if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    [void](New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $env:COMPUTERNAME)
}
Set-Location "${SiteCode}:\"
$systems = @(Get-CMSiteSystemServer -Name $SiteServer)
if ($systems.Count -ne 1) { throw 'Expected exactly one site system for the service connection point.' }
$system = $systems[0]
$properties = @{}
foreach ($property in $system.Props) { $properties[$property.PropertyName] = $property }
$proxyMatches = $properties['UseProxy'].Value -eq 1 -and
    $properties['AnonymousProxyAccess'].Value -eq 0 -and
    $properties['ProxyName'].Value2 -eq $ProxyName -and
    $properties['ProxyServerPort'].Value -eq $ProxyPort -and
    $properties['ProxyUserName'].Value2 -eq $ProxyAccount
if (-not $proxyMatches) {
    $accounts = @(Get-CMAccount -Name $ProxyAccount)
    if ($accounts.Count -ne 1) { throw 'Register the specified proxy account in Configuration Manager before configuring authenticated proxy access.' }
    $system | Set-CMSiteSystemServer -EnableProxy $true -ProxyServerName $ProxyName -ProxyServerPort $ProxyPort -ProxyAccessAccount $accounts[0]
    $Ansible.Changed = $true
}
$Ansible.Result = @{ site_system = $SiteServer; proxy = $ProxyName; port = $ProxyPort; account = $ProxyAccount }
