param([string]$SiteCode, [int]$ExpectedBuild)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$site = Get-CimInstance -Namespace "root\SMS\site_$SiteCode" -ClassName SMS_Site -OperationTimeoutSec 15 |
    Where-Object SiteCode -eq $SiteCode
if (-not $site -or [int]$site.BuildNumber -ne $ExpectedBuild) {
    throw 'SMS Provider has not reported the requested site build.'
}
# The provider can initially expose Version=5.0. Use its dedicated build field,
# and correlate that with the full installed version in the setup registry.
$fullVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\SMS\Setup').'Full Version'
if (-not $fullVersion -or ([version]$fullVersion).Build -ne $ExpectedBuild) {
    throw 'The setup registry version does not match the SMS Provider build.'
}
$Ansible.Result = @{ site_code = $site.SiteCode; version = $fullVersion; reported_version = $site.Version; build_number = $site.BuildNumber }
