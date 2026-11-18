param([string]$Setup, [string]$AnswerFile)
$ErrorActionPreference = 'Stop'
if (-not (Get-WindowsFeature NET-Framework-Core).Installed) {
    throw '.NET Framework 3.5 must be enabled before starting the ConfigMgr setup bootstrapper. Complete any required restart first.'
}
foreach ($directory in @('System32', 'SysWOW64')) {
    $runtime = Join-Path $env:WINDIR "$directory\vcruntime140.dll"
    if (-not (Test-Path $runtime)) { throw 'Install both x86 and x64 Visual C++ runtimes before ConfigMgr setup.' }
    $info = (Get-Item $runtime).VersionInfo
    $version = [version]('{0}.{1}.{2}.{3}' -f $info.FileMajorPart, $info.FileMinorPart, $info.FileBuildPart, $info.FilePrivatePart)
    if ($version -lt [version]'14.34.0.0') {
        throw 'OLE DB 19 requires Visual C++ version 14.34 or later for both x86 and x64. Update both runtimes before ConfigMgr setup.'
    }
}
$process = Start-Process -FilePath $Setup -ArgumentList "/script `"$AnswerFile`"" -Wait -PassThru
if ($process.ExitCode -notin @(0, 3010)) {
    throw "Configuration Manager setup failed ($($process.ExitCode)). Review C:\ConfigMgrSetup.log and C:\ConfigMgrPrereq.log on the site server."
}
$Ansible.Changed = $true
