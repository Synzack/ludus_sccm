#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        site_code = @{ type = 'str'; required = $true }
        ActiveDirectoryForestDiscovery = @{ type = 'bool'; required = $true }
        EnableActiveDirectorySiteBoundaryCreation = @{ type = 'bool'; required = $true }
        EnableSubnetBoundaryCreation = @{ type = 'bool'; required = $true }
        ActiveDirectoryGroupDiscovery = @{ type = 'bool'; required = $true }
        ActiveDirectorySystemDiscovery = @{ type = 'bool'; required = $true }
        ActiveDirectoryUserDiscovery = @{ type = 'bool'; required = $true }
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

if($module.Params.ActiveDirectoryForestDiscovery){
    Set-CMDiscoveryMethod -ActiveDirectoryForestDiscovery -SiteCode $module.Params.site_code -Enabled $True -EnableActiveDirectorySiteBoundaryCreation $module.Params.EnableActiveDirectorySiteBoundaryCreation -EnableSubnetBoundaryCreation $module.Params.EnableSubnetBoundaryCreation

    Invoke-CMForestDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.ActiveDirectoryGroupDiscovery){
    $GroupDiscoveryScope = New-CMADGroupDiscoveryScope -Name "Domain Groups" -LdapLocation $container -RecursiveSearch $True

    Set-CMDiscoveryMethod -ActiveDirectoryGroupDiscovery -SiteCode $module.Params.site_code -Enabled $True -AddGroupDiscoveryScope $GroupDiscoveryScope

    Invoke-CMGroupDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.ActiveDirectorySystemDiscovery){
    Set-CMDiscoveryMethod -ActiveDirectorySystemDiscovery -SiteCode $module.Params.site_code -Enabled $True -AddActiveDirectoryContainer $container

    Invoke-CMSystemDiscovery -SiteCode $module.Params.site_code
}

if($module.Params.ActiveDirectoryUserDiscovery){
    Set-CMDiscoveryMethod -ActiveDirectoryUserDiscovery -SiteCode $module.Params.site_code -Enabled $True -AddActiveDirectoryContainer $container

    Invoke-CMUserDiscovery -SiteCode $module.Params.site_code
}

$module.ExitJson()