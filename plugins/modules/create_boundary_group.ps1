#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        site_code = @{ type = 'str'; required = $true }
        boundary_group_name = @{ type = 'str'; required = $true }
        boundary_group_description = @{ type = 'str'; required = $true }
        site_system_server_names = @{ type = 'list'; required = $true }
        boundary = @{ type = 'str'; required = $true }
    }
    supports_check_mode = $true
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Import-Module "C:\\Program Files (x86)\\Microsoft Configuration Manager\\AdminConsole\\bin\\ConfigurationManager.psd1"

if ((Get-PSDrive -Name $module.Params.site_code -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
{
    $ProviderMachineName = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\ConfigMgr10\AdminUI\Connection -Name Server).Server
    New-PSDrive -Name $module.Params.site_code -PSProvider CMSite -Root $ProviderMachineName 
}

Set-Location "$($module.Params.site_code):\"

#Check if boundary group exists
 $bg_exists = Get-CMBoundaryGroup -Name $module.Params.boundary_group_name
 if(-not $bg_exists){
     #Create boundary group and description
    New-CMBoundaryGroup -Name $module.Params.boundary_group_name -Description $module.Params.boundary_group_description
 }
    
#Configure boundary group
Set-CMBoundaryGroup -Name $module.Params.boundary_group_name -DefaultSiteCode $module.Params.site_code

foreach($server in $module.Params.site_system_server_names){
    $get_server = Get-CMSiteSystemServer -Name $server
    Set-CMBoundaryGroup -Name $module.Params.boundary_group_name -AddSiteSystemServer $get_server 
}

#Link to boundary
Add-CMBoundaryToGroup -BoundaryGroupName $module.Params.boundary_group_name -BoundaryName $module.Params.boundary
$module.ExitJson()
