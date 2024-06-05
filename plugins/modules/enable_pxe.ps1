#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        site_code = @{ type = 'str'; required = $true }
        toggle_password = @{ type = 'bool'; required = $true }
        password = @{ type = 'str'; required = $true }
    }
    supports_check_mode = $true
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Import-Module "C:\\Program Files (x86)\\Microsoft Configuration Manager\\AdminConsole\\bin\\ConfigurationManager.psd1"

#https://www.windows-noob.com/forums/topic/16422-connect-configmgr64-function-to-connect-to-cmsite-sccm-feedback-for-improvement/
if ((Get-PSDrive -Name $module.Params.site_code -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
{
    $ProviderMachineName = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\ConfigMgr10\AdminUI\Connection -Name Server).Server
    New-PSDrive -Name $module.Params.site_code -PSProvider CMSite -Root $ProviderMachineName 
}

Set-Location "$($module.Params.site_code):\"

$DP = Get-CMDistributionPoint

if($module.Params.toggle_password){
    $password = ConvertTo-SecureString -String $module.Params.password -AsPlainText -Force

    Set-CMDistributionPoint -InputObject $DP -PxePassword $password -EnablePXE $True -AllowPxeResponse $true -EnableUnknownComputerSupport $true -UserDeviceAffinity AllowWithAutomaticApproval

    $module.ExitJson()
} else {
    Set-CMDistributionPoint -InputObject $DP -EnablePXE $True -AllowPxeResponse $true -EnableUnknownComputerSupport $true -UserDeviceAffinity AllowWithAutomaticApproval 

    $module.ExitJson()
}
