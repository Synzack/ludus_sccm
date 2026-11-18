param([string]$SiteCode, [string]$ImageName = 'Windows11')
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
Import-Module ConfigurationManager -ErrorAction Stop
if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    [void](New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $env:COMPUTERNAME)
}
Set-Location "${SiteCode}:\"
$images = @(Get-CMOperatingSystemImage -Name $ImageName) + @(Get-CMBootImage -Name 'Boot image (x64)')
if ($images.Count -ne 2) { throw 'The OS image and x64 boot image must both exist.' }
$points = @(Get-CMDistributionPoint)
if (-not $points) { throw 'No distribution point is configured.' }
foreach ($image in $images) {
    $states = @(Get-CimInstance -Namespace "root\SMS\site_$SiteCode" -ClassName SMS_PackageStatusDistPointsSummarizer -Filter "PackageID='$($image.PackageID)'" -OperationTimeoutSec 15)
    foreach ($point in $points) {
        $server = $point.NetworkOSPath.TrimStart('\')
        $state = @($states | Where-Object ServerNALPath -Match ([regex]::Escape($server)))
        if ($state.Count -ne 1 -or $state[0].State -ne 0 -or $state[0].SourceVersion -ne $image.SourceVersion) {
            throw "Content $($image.PackageID) version $($image.SourceVersion) is not yet installed on $server."
        }
    }
}
$Ansible.Result = @{ packages = @($images.PackageID); distribution_points = @($points.NetworkOSPath) }
