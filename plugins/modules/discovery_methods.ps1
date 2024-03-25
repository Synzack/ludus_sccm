#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        site_code = @{ type = 'str'; required = $true }
        ludus_sccm_enable_active_directory_forest_discovery = @{ type = 'bool'; required = $true }
        ludus_sccm_enable_active_directory_boundary_creation = @{ type = 'bool'; required = $true }
        ludus_sccm_enable_subnet_boundary_creation = @{ type = 'bool'; required = $true }
        ludus_sccm_enable_active_directory_group_discovery = @{ type = 'bool'; required = $true }
        ludus_sccm_enable_active_directory_system_discovery = @{ type = 'bool'; required = $true }
        ludus_sccm_enable_active_directory_user_discovery = @{ type = 'bool'; required = $true }
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

if($module.Params.ludus_sccm_enable_active_directory_forest_discovery){
    Set-CMDiscoveryMethod -ludus_sccm_enable_active_directory_forest_discovery -SiteCode $module.Params.site_code -Enabled $True -ludus_sccm_enable_active_directory_boundary_creation $module.Params.ludus_sccm_enable_active_directory_boundary_creation -ludus_sccm_enable_subnet_boundary_creation $module.Params.ludus_sccm_enable_subnet_boundary_creation

    Invoke-CMForestDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.ludus_sccm_enable_active_directory_group_discovery){
    $GroupDiscoveryScope = New-CMADGroupDiscoveryScope -Name "Domain Groups" -LdapLocation $container -RecursiveSearch $True

    Set-CMDiscoveryMethod -ludus_sccm_enable_active_directory_group_discovery -SiteCode $module.Params.site_code -Enabled $True -AddGroupDiscoveryScope $GroupDiscoveryScope

    Invoke-CMGroupDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.ludus_sccm_enable_active_directory_system_discovery){
    Set-CMDiscoveryMethod -ludus_sccm_enable_active_directory_system_discovery -SiteCode $module.Params.site_code -Enabled $True -AddActiveDirectoryContainer $container

    Invoke-CMSystemDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.ludus_sccm_enable_active_directory_user_discovery){
    Set-CMDiscoveryMethod -ludus_sccm_enable_active_directory_user_discovery -SiteCode $module.Params.site_code -Enabled $True -AddActiveDirectoryContainer $container

    Invoke-CMUserDiscovery -SiteCode $module.Params.site_code
}

$module.ExitJson()