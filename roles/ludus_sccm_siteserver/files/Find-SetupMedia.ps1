param([string]$MediaPath, [int]$ExpectedBuild)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$setups = @(Get-ChildItem -LiteralPath $MediaPath -Filter setup.exe -File -Recurse |
    Where-Object { $_.FullName -match '\\SMSSETUP\\BIN\\X64\\setup\.exe$' })
if ($setups.Count -ne 1) { throw "Expected exactly one SMSSETUP\BIN\X64\setup.exe under $MediaPath; found $($setups.Count)." }
$setup = $setups[0]
if ($setup.VersionInfo.FileBuildPart -ne $ExpectedBuild) {
    throw "Extracted setup build $($setup.VersionInfo.FileBuildPart) does not match $ExpectedBuild."
}
$Ansible.Result = @{ root = $setup.Directory.Parent.Parent.Parent.FullName; setup = $setup.FullName }
