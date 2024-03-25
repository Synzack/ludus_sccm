#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        site_code = @{ type = 'str'; required = $true }
    }
    supports_check_mode = $true
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Import-Module "C:\\Program Files (x86)\\Microsoft Configuration Manager\\AdminConsole\\bin\\ConfigurationManager.psd1"

#https://www.oscc.be/sccm/configmgr/powershell/naa/Set-NAA-using-Powershell-in-CB/
#https://www.windows-noob.com/forums/topic/16422-connect-configmgr64-function-to-connect-to-cmsite-sccm-feedback-for-improvement/
if ((Get-PSDrive -Name $module.Params.site_code -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
{
    $ProviderMachineName = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\ConfigMgr10\AdminUI\Connection -Name Server).Server
    New-PSDrive -Name $module.Params.site_code -PSProvider CMSite -Root $ProviderMachineName 
}

Set-Location "$($module.Params.site_code):\"

#Query for NAA Account
$component = gwmi -class SMS_SCI_ClientComp -Namespace "root\sms\site_$($module.Params.site_code)"  | Where-Object {$_.ItemName -eq "Software Distribution"}
$props = $component.PropLists
$prop = $props | where {$_.PropertyListName -eq "Network Access User Names"}


#Make CMAccount Network Access Account or Exit if Exists
$exists = $module.Params.name -eq $prop.Values
if($exists) {
    $module.ExitJson()
} else {
    $new = [WmiClass] "root\sms\site_$($module.Params.site_code):SMS_EmbeddedPropertyList"
    $embeddedpropertylist = $new.CreateInstance()

    $embeddedpropertylist.PropertyListName = "Network Access User Names"
    $embeddedpropertylist.Values = $module.Params.name
    $component.PropLists = $embeddedpropertylist
    $component.Put() | Out-Null
    $module.ExitJson()
}

