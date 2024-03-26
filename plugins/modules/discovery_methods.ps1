#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        site_code = @{ type = 'str'; required = $true }
        enable_forest_discovery = @{ type = 'bool'; required = $true }
        enable_ad_boundary_creation = @{ type = 'bool'; required = $true }
        enable_subnet_boundary_creation = @{ type = 'bool'; required = $true }
        enable_active_directory_group_discovery = @{ type = 'bool'; required = $true }
        enable_active_directory_system_discovery = @{ type = 'bool'; required = $true }
        enable_active_directory_user_discovery = @{ type = 'bool'; required = $true }
        # HeartbeatDiscovery = @{ type = 'bool'; required = $true }
        # NetworkDiscovery = @{ type = 'bool'; required = $true }
    }
    supports_check_mode = $true
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Import-Module "C:\\Program Files (x86)\\Microsoft Configuration Manager\\AdminConsole\\bin\\ConfigurationManager.psd1"
Import-Module ActiveDirectory
$domainInfo = Get-ADDomain
$container = "LDAP://"+$domainInfo.DistinguishedName

if ((Get-PSDrive -Name $module.Params.site_code -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
{
    $ProviderMachineName = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\ConfigMgr10\AdminUI\Connection -Name Server).Server
    New-PSDrive -Name $module.Params.site_code -PSProvider CMSite -Root $ProviderMachineName 
}

Set-Location "$($module.Params.site_code):\"
$enabled_ActiveDirectoryForestDiscovery = Get-CMDiscoveryMethod -Name "ActiveDirectoryForestDiscovery" | Where-Object {$_.Flag -eq 6}
$enabled_ActiveDirectoryGroupDiscovery = Get-CMDiscoveryMethod -Name "ActiveDirectoryGroupDiscovery" | Where-Object {$_.Flag -eq 6}
$enabled_ActiveDirectorySystemDiscovery = Get-CMDiscoveryMethod -Name "ActiveDirectorySystemDiscovery" | Where-Object {$_.Flag -eq 6}
$enabled_ActiveDirectoryUserDiscovery = Get-CMDiscoveryMethod -Name "ActiveDirectoryUserDiscovery" | Where-Object {$_.Flag -eq 6}

if($module.Params.enable_forest_discovery -and (-not $enabled_ActiveDirectoryForestDiscovery)){
    Set-CMDiscoveryMethod -ActiveDirectoryForestDiscovery -SiteCode $module.Params.site_code -Enabled $True -EnableActiveDirectorySiteBoundaryCreation $module.Params.enable_ad_boundary_creation -EnableSubnetBoundaryCreation $module.Params.enable_subnet_boundary_creation

    Invoke-CMForestDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.enable_active_directory_group_discovery -and (-not $enabled_ActiveDirectoryGroupDiscovery)){
    $GroupDiscoveryScope = New-CMADGroupDiscoveryScope -Name "Domain Groups" -LdapLocation $container -RecursiveSearch $True

    Set-CMDiscoveryMethod -ActiveDirectoryGroupDiscovery -SiteCode $module.Params.site_code -Enabled $True -AddGroupDiscoveryScope $GroupDiscoveryScope

    Invoke-CMGroupDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.enable_active_directory_system_discovery -and (-not $enabled_ActiveDirectorySystemDiscovery)){
    Set-CMDiscoveryMethod -ActiveDirectorySystemDiscovery -SiteCode $module.Params.site_code -Enabled $True -AddActiveDirectoryContainer $container

    Invoke-CMSystemDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.enable_active_directory_user_discovery -and (-not $enabled_ActiveDirectoryUserDiscovery)){
    Set-CMDiscoveryMethod -ActiveDirectoryUserDiscovery -SiteCode $module.Params.site_code -Enabled $True -AddActiveDirectoryContainer $container

    Invoke-CMUserDiscovery -SiteCode $module.Params.site_code
}

$module.ExitJson()
