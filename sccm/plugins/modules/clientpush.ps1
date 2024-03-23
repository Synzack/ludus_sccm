#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        site_code = @{ type = 'str'; required = $true }
        EnableAutomaticClientPushInstallation = @{ type = 'bool'; required = $true }
        EnableSystemTypeConfigurationManager = @{ type = 'bool'; required = $true }
        EnableSystemTypeServer = @{ type = 'bool'; required = $true }
        EnableSystemTypeWorkstation = @{ type = 'bool'; required = $true }
        InstallClientToDomainController = @{ type = 'bool'; required = $true }
        AllownNTLMFallback = @{ type = 'bool'; required = $true }
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


#Get Current Push Client Settings
$currentPushSettings = Get-CMClientPushInstallation
$PropList = $currentPushSettings.PropLists
$currentPushAccountSettings = $PropList | ? { $_.PropertyListName -eq "Reserved2"}
$currentPushAccount = $currentPushAccountSettings.Values

# #Check if Account Already Exists
$accountExists = $module.Params.name -eq $PropList 

#Configure Account if Not Exists
#https://learn.microsoft.com/en-us/powershell/module/configurationmanager/set-cmclientpushinstallation?view=sccm-ps
if($accountExists) {
    continue
} else {
    Set-CMClientPushInstallation -SiteCode $module.Params.site_code -ChosenAccount $module.Params.name -EnableAutomaticClientPushInstallation $module.Params.EnableAutomaticClientPushInstallation -EnableSystemTypeConfigurationManager $module.Params.EnableSystemTypeConfigurationManager -EnableSystemTypeServer $module.Params.EnableSystemTypeServer -EnableSystemTypeWorkstation $module.Params.EnableSystemTypeWorkstation -InstallClientToDomainController $module.Params.InstallClientToDomainController -AllownNTLMFallback $module.Params.AllownNTLMFallback
}

#Set Properties
#$props = $currentPushSettings.Props
$module.ExitJson()