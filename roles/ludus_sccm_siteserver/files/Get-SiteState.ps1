param([string]$SiteCode, [int]$ExpectedBuild)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$setup = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\SMS\Setup' -ErrorAction SilentlyContinue
$installed = $null
if ($setup) {
    $installed = $setup.'Full Version'
    if (-not $installed) { $installed = $setup.Version }
}
if ($installed) {
    $version = [version]$installed
    if ($version.Build -ne $ExpectedBuild) {
        throw "Existing Configuration Manager $installed does not match requested build $ExpectedBuild. This role provisions fresh sites; use supported in-console servicing for upgrades."
    }
}
$Ansible.Result = @{ installed = [bool]$installed; version = [string]$installed }
