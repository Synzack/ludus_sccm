$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
if ((Get-Service Winmgmt).Status -ne 'Running') {
    throw 'Windows Management Instrumentation is not running. Complete the pending restart before provisioning.'
}
$boot = (Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 15).LastBootUpTime.ToUniversalTime()
$marker = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\WBEM\CIMOM' -ErrorAction SilentlyContinue
if ($marker.LastServiceReady) {
    $ready = [datetime]::FromFileTimeUtc([long]$marker.LastServiceReady)
    if ($ready -lt $boot) {
        throw 'The WMI readiness timestamp predates this boot, often after a large clock correction. Reboot this guest before installing Windows features.'
    }
}
