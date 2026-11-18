# Run with Windows PowerShell 5.1. No Pester installation or lab credentials needed.
param([string]$SourceRoot = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$files = Join-Path $SourceRoot 'roles\ludus_sccm_siteserver\files'
$script:Passed = 0
function Assert-True($Condition, $Message) {
    if (-not $Condition) { throw $Message }
    $script:Passed++
}
function Assert-Throws([scriptblock]$Action, [string]$Pattern) {
    $failure = $null
    try { & $Action } catch { $failure = $_.Exception.Message }
    Assert-True ($failure -match $Pattern) "Expected failure matching '$Pattern', received '$failure'."
}
$parseFiles = @(Get-ChildItem (Join-Path $SourceRoot 'roles') -Filter '*.ps1' -Recurse) +
    @(Get-ChildItem (Join-Path $SourceRoot 'plugins\modules') -Filter '*.ps1')
foreach ($file in $parseFiles) {
    $tokens = $null; $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    Assert-True ($errors.Count -eq 0) "PowerShell parser errors in $file : $errors"
}
$state = [scriptblock]::Create((Get-Content (Join-Path $files 'Get-SiteState.ps1') -Raw))
$media = [scriptblock]::Create((Get-Content (Join-Path $files 'Find-SetupMedia.ps1') -Raw))
$setup = [scriptblock]::Create((Get-Content (Join-Path $files 'Invoke-SiteSetup.ps1') -Raw))
$Ansible = @{ Changed = $true; Result = $null }
$preflight = [scriptblock]::Create((Get-Content (Join-Path $SourceRoot 'roles\ludus_sccm_prerequisites\files\Test-WindowsReadiness.ps1') -Raw))
$script:Boot = [datetime]::Parse('2026-11-17T21:00:00Z').ToUniversalTime()
$script:Ready = $script:Boot.AddSeconds(10)
$script:WmiStatus = 'Running'
function Get-Service { param($Name) return @{ Status = $script:WmiStatus } }
function Get-CimInstance { param($ClassName, $OperationTimeoutSec) return @{ LastBootUpTime = $script:Boot } }
function Get-ItemProperty { param($Path, $ErrorAction) return @{ LastServiceReady = $script:Ready.ToFileTimeUtc() } }
& $preflight
Assert-True (-not $Ansible.Changed) 'A ready guest must pass without changing Windows services.'
$script:Ready = $script:Boot.AddHours(-2)
Assert-Throws { & $preflight } 'Reboot this guest'
$script:WmiStatus = 'StopPending'
Assert-Throws { & $preflight } 'not running'

$verify = [scriptblock]::Create((Get-Content (Join-Path $files 'Test-SiteVersion.ps1') -Raw))
$script:ProviderSite = [pscustomobject]@{ SiteCode='123'; Version='5.0'; BuildNumber=9141 }
$script:Installed = @{ 'Full Version' = '5.00.9141.1000' }
function Get-CimInstance { param($Namespace, $ClassName, $OperationTimeoutSec) return $script:ProviderSite }
function Get-ItemProperty { param($Path, $ErrorAction) return $script:Installed }
& $verify -SiteCode '123' -ExpectedBuild 9141
Assert-True ($Ansible.Result.version -eq '5.00.9141.1000') 'A provider reporting Version=5.0 must be checked by its build and the full installed version.'
$script:ProviderSite.BuildNumber = 9106
Assert-Throws { & $verify -SiteCode '123' -ExpectedBuild 9141 } 'requested site build'
$script:ProviderSite.BuildNumber = 9141
$script:Installed = @{ 'Full Version' = '5.00.9106.1000' }
Assert-Throws { & $verify -SiteCode '123' -ExpectedBuild 9141 } 'does not match'

function Get-ItemProperty { param($Path, $ErrorAction) return $script:Installed }
$script:Installed = $null
& $state -SiteCode '123' -ExpectedBuild 9141
Assert-True (-not $Ansible.Result.installed) 'A fresh server must require installation.'
$script:Installed = @{ 'Full Version' = '5.00.9141.1000' }
& $state -SiteCode '123' -ExpectedBuild 9141
Assert-True ($Ansible.Result.installed -and -not $Ansible.Changed) '2509 must be recognized without reporting a change.'
$script:Installed = @{ 'Full Version' = '5.00.9106.1000' }
Assert-Throws { & $state -SiteCode '123' -ExpectedBuild 9141 } 'does not match'
function Get-ChildItem { param($LiteralPath, $Filter, [switch]$File, [switch]$Recurse) return $script:Setups }
$script:Setups = @()
Assert-Throws { & $media -MediaPath 'C:\media\2509' -ExpectedBuild 9141 } 'found 0'
$item = [pscustomobject]@{
    FullName = 'C:\media\2509\cd.retail.LN\SMSSETUP\BIN\X64\setup.exe'
    VersionInfo = [pscustomobject]@{ FileBuildPart = 9141 }
    Directory = [System.IO.DirectoryInfo]'C:\media\2509\cd.retail.LN\SMSSETUP\BIN\X64'
}
$script:Setups = @($item)
& $media -MediaPath 'C:\media\2509' -ExpectedBuild 9141
Assert-True ($Ansible.Result.root -eq 'C:\media\2509\cd.retail.LN') 'Nested evaluation media must resolve to the CD root.'
$item.VersionInfo.FileBuildPart = 9106
Assert-Throws { & $media -MediaPath 'C:\media\2509' -ExpectedBuild 9141 } 'does not match'
$item.VersionInfo.FileBuildPart = 9141
$script:Setups = @($item, $item)
Assert-Throws { & $media -MediaPath 'C:\media\2509' -ExpectedBuild 9141 } 'found 2'
$script:NetfxInstalled = $true
$script:SetupLaunches = 0
function Get-WindowsFeature { param($Name) return @{ Installed = $script:NetfxInstalled } }
$script:RuntimeX86Minor = 44
function Test-Path { param($Path) return $true }
function Get-Item {
    param($Path)
    $minor = if ($Path -like '*SysWOW64*') { $script:RuntimeX86Minor } else { 44 }
    return @{ VersionInfo = @{ FileMajorPart=14; FileMinorPart=$minor; FileBuildPart=35211; FilePrivatePart=0 } }
}
function Start-Process { param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru) $script:SetupLaunches++; return @{ ExitCode = $script:ExitCode } }
foreach ($code in @(0,3010)) {
    $script:ExitCode = $code
    & $setup -Setup 'C:\media\setup.exe' -AnswerFile 'C:\space path\setup.ini'
    Assert-True $Ansible.Changed "Setup success $code must report a change."
}
$script:ExitCode = 1603
Assert-Throws { & $setup -Setup 'C:\media\setup.exe' -AnswerFile 'C:\setup.ini' } 'failed \(1603\)'
$script:RuntimeX86Minor = 29
$launchesBefore = $script:SetupLaunches
Assert-Throws { & $setup -Setup 'C:\media\setup.exe' -AnswerFile 'C:\setup.ini' } 'both x86 and x64'
Assert-True ($script:SetupLaunches -eq $launchesBefore) 'An old x86 runtime must fail before OLE DB setup can return MSI error 1603.'
$script:RuntimeX86Minor = 44
$script:NetfxInstalled = $false
$launchesBefore = $script:SetupLaunches
Assert-Throws { & $setup -Setup 'C:\media\setup.exe' -AnswerFile 'C:\setup.ini' } '\.NET Framework 3.5'
Assert-True ($script:SetupLaunches -eq $launchesBefore) 'Missing .NET 3.5 must fail before a setup process can wait on an invisible prompt.'
$content = [scriptblock]::Create((Get-Content (Join-Path $files 'Test-OsdContent.ps1') -Raw))
function Import-Module { param($Name, $ErrorAction) }
function Get-PSDrive { param($Name, $PSProvider, $ErrorAction) return @{ Name=$Name } }
function Set-Location { param($Path) }
function Get-CMOperatingSystemImage { param($Name) return [pscustomobject]@{ PackageID='ABC00001'; SourceVersion=2 } }
function Get-CMBootImage { param($Name) return [pscustomobject]@{ PackageID='ABC00002'; SourceVersion=2 } }
$script:HasPoint = $true
function Get-CMDistributionPoint { if ($script:HasPoint) { return [pscustomobject]@{ NetworkOSPath='\\dp.example.test' } } }
$script:ContentState = 0
$script:ContentVersion = 2
function Get-CimInstance {
    param($Namespace, $ClassName, $Filter, $OperationTimeoutSec)
    return [pscustomobject]@{ ServerNALPath='\\dp.example.test\'; State=$script:ContentState; SourceVersion=$script:ContentVersion }
}
& $content -SiteCode 'ABC'
Assert-True ($Ansible.Result.packages.Count -eq 2 -and -not $Ansible.Changed) 'Both current content versions must be installed before allowing a later reboot.'
$script:ContentState = 7
Assert-Throws { & $content -SiteCode 'ABC' } 'not yet installed'
$script:ContentState = 0
$script:ContentVersion = 1
Assert-Throws { & $content -SiteCode 'ABC' } 'not yet installed'
$script:HasPoint = $false
Assert-Throws { & $content -SiteCode 'ABC' } 'No distribution point'
$proxy = [scriptblock]::Create((Get-Content (Join-Path $files 'Set-SiteProxy.ps1') -Raw))
$script:ProxyChanges = 0
$script:HasProxyAccount = $true
$script:ProxyUser = 'EXAMPLE\proxyservice'
function Get-CMSiteSystemServer {
    param($Name)
    return [pscustomobject]@{ Props=@(
        [pscustomobject]@{ PropertyName='UseProxy'; Value=1 },
        [pscustomobject]@{ PropertyName='AnonymousProxyAccess'; Value=0 },
        [pscustomobject]@{ PropertyName='ProxyName'; Value2='proxy.example.test' },
        [pscustomobject]@{ PropertyName='ProxyServerPort'; Value=3128 },
        [pscustomobject]@{ PropertyName='ProxyUserName'; Value2=$script:ProxyUser }
    ) }
}
function Get-CMAccount { param($Name) if ($script:HasProxyAccount) { return @{ UserName=$Name } } }
function Set-CMSiteSystemServer { param($EnableProxy, $ProxyServerName, $ProxyServerPort, $ProxyAccessAccount) $script:ProxyChanges++ }
& $proxy -SiteCode ABC -SiteServer site.example.test -ProxyName proxy.example.test -ProxyPort 3128 -ProxyAccount 'EXAMPLE\proxyservice'
Assert-True (-not $Ansible.Changed -and $script:ProxyChanges -eq 0) 'An unchanged proxy configuration must not be rewritten.'
$script:ProxyUser = ''
& $proxy -SiteCode ABC -SiteServer site.example.test -ProxyName proxy.example.test -ProxyPort 3128 -ProxyAccount 'EXAMPLE\proxyservice'
Assert-True ($Ansible.Changed -and $script:ProxyChanges -eq 1) 'A missing proxy authentication account must be configured.'
$script:HasProxyAccount = $false
Assert-Throws { & $proxy -SiteCode ABC -SiteServer site.example.test -ProxyName proxy.example.test -ProxyPort 3128 -ProxyAccount 'EXAMPLE\proxyservice' } 'Register the specified proxy account'
Write-Output "$script:Passed assertions passed on Windows PowerShell $($PSVersionTable.PSVersion)."
