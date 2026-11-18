#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        password = @{ type = 'str'; required = $true; no_log = $true }
        site_code = @{ type = 'str'; required = $true }
    }
    supports_check_mode = $true
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Import-Module ConfigurationManager -ErrorAction Stop

#https://www.windows-noob.com/forums/topic/16422-connect-configmgr64-function-to-connect-to-cmsite-sccm-feedback-for-improvement/
if ((Get-PSDrive -Name $module.Params.site_code -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
{
    $ProviderMachineName = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\ConfigMgr10\AdminUI\Connection -Name Server).Server
    New-PSDrive -Name $module.Params.site_code -PSProvider CMSite -Root $ProviderMachineName 
}

Set-Location "$($module.Params.site_code):\"

$account = Get-CMAccount -Username $module.Params.name

if(-not $account) {
    #https://learn.microsoft.com/en-us/powershell/module/configurationmanager/new-cmaccount?view=sccm-ps
    $SecurePassword = ConvertTo-SecureString -String $module.Params.password -AsPlainText -Force
    New-CMAccount -Name $module.Params.name -Password $SecurePassword -Sitecode $module.Params.site_code
    $module.ExitJson()
} else {
    $module.ExitJson()
}