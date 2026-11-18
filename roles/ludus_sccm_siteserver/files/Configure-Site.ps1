param([string]$SiteCode, [string]$SqlServer, [bool]$EnhancedHttp, [int]$CompatibilityLevel)
$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false
# SQL Server 2022 defaults to level 160; ConfigMgr 2509 uses supported level 150.
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$SqlServer;Database=master;Integrated Security=SSPI;Encrypt=True;TrustServerCertificate=True"
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = 'SELECT compatibility_level FROM sys.databases WHERE name = @database'
    [void]$command.Parameters.AddWithValue('@database', "CM_$SiteCode")
    $level = $command.ExecuteScalar()
    if (-not $level) { throw "Site database CM_$SiteCode does not exist." }
    if ([int]$level -ne $CompatibilityLevel) {
        if ($SiteCode -notmatch '^[A-Za-z0-9]{3}$' -or $CompatibilityLevel -ne 150) { throw 'Invalid SQL compatibility configuration.' }
        $command.CommandText = "ALTER DATABASE [CM_$SiteCode] SET COMPATIBILITY_LEVEL = $CompatibilityLevel"
        [void]$command.ExecuteNonQuery()
        $Ansible.Changed = $true
    }
} finally { $connection.Dispose() }
Import-Module ConfigurationManager -ErrorAction Stop
if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    [void](New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $env:COMPUTERNAME)
}
Set-Location "${SiteCode}:\"
# IISSSLState bit 1024 represents Configuration Manager generated certificates.
$component = Get-CMSiteComponent -ComponentName 'SMS_Site_Component_Manager' -SiteCode $SiteCode
$property = @($component.Props | Where-Object PropertyName -eq 'IISSSLState')[0]
if (-not $property) { throw 'Cannot read the site communication security state.' }
$enabled = ([int]$property.Value -band 1024) -ne 0
if ($enabled -ne $EnhancedHttp) {
    Set-CMSite -SiteCode $SiteCode -UseSmsGeneratedCert $EnhancedHttp
    $Ansible.Changed = $true
}
