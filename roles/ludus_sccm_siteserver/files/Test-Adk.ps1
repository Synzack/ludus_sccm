param([int]$ExpectedBuild, [switch]$RequireInstalled)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
$root = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit"
$dism = Join-Path $root 'Deployment Tools\amd64\DISM\dism.exe'
$winpe = Join-Path $root 'Windows Preinstallation Environment\amd64\en-us\winpe.wim'
if ($RequireInstalled -and (-not (Test-Path $dism) -or -not (Test-Path $winpe))) {
    throw 'The ADK Deployment Tools and WinPE add-on must both be installed.'
}
if ((Test-Path $dism) -and (Get-Item $dism).VersionInfo.FileBuildPart -ne $ExpectedBuild) {
    throw 'An incompatible ADK is installed. Remove the ADK and WinPE add-on and reboot before provisioning.'
}
if (Test-Path $winpe) {
    $image = Get-WindowsImage -ImagePath $winpe -Index 1
    if (([version]$image.Version).Build -ne $ExpectedBuild) {
        throw 'An incompatible WinPE add-on is installed. Remove it and install the add-on matching the ADK.'
    }
}
