#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        site_code = @{ type = 'str'; required = $true }
        ludus_sccm_enable_automatic_client_push_installation = @{ type = 'bool'; required = $true }
        ludus_sccm_enable_system_type_configuration_manager = @{ type = 'bool'; required = $true }
        ludus_sccm_enable_system_type_server = @{ type = 'bool'; required = $true }
        ludus_sccm_enable_system_type_workstation = @{ type = 'bool'; required = $true }
        ludus_sccm_install_client_to_domain_controller = @{ type = 'bool'; required = $true }
        ludus_sccm_allow_NTLM_fallback = @{ type = 'bool'; required = $true }
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


# Get Current Push Client Settings
$currentPushSettings = Get-CMClientPushInstallation
$PropList = $currentPushSettings.PropLists
$currentPushAccountSettings = $PropList | ? { $_.PropertyListName -eq "Reserved2"}
$currentPushAccount = $currentPushAccountSettings.Values

# Check if Account Already Exists
$accountExists = $module.Params.name -eq $PropList 

# Configure Account if Not Exists
# https://learn.microsoft.com/en-us/powershell/module/configurationmanager/set-cmclientpushinstallation?view=sccm-ps
if($accountExists) {
    continue
} else {
    Set-CMClientPushInstallation -SiteCode $module.Params.site_code -ChosenAccount $module.Params.name -EnableAutomaticClientPushInstallation $module.Params.ludus_sccm_enable_automatic_client_push_installation -EnableSystemTypeConfigurationManager $module.Params.ludus_sccm_enable_system_type_configuration_manager -EnableSystemTypeServer $module.Params.ludus_sccm_enable_system_type_server -EnableSystemTypeWorkstation $module.Params.ludus_sccm_enable_system_type_workstation -InstallClientToDomainController $module.Params.ludus_sccm_install_client_to_domain_controller -AllownNTLMFallback $module.Params.ludus_sccm_allow_NTLM_fallback
}

# Set Properties
# $props = $currentPushSettings.Props
$module.ExitJson()
