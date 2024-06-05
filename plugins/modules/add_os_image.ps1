#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        site_code = @{ type = 'str'; required = $true }
        path = @{ type = 'str'; required = $true }
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

$osExists = Get-CMOperatingSystemImage -Name $module.Params.name

if($osExists) {
    $module.ExitJson()
} else {
    New-CMOperatingSystemImage -Name $module.Params.name -Path $module.Params.path

    $DP = Get-CMDistributionPoint
    $DP_FQDN = $DP.NetworkOSPath -replace "\\", ""

    Start-CMContentDistribution -BootImageName "Boot image (x64)" -DistributionPointName $DP_FQDN
    Start-CMContentDistribution -OperatingSystemImageName $module.Params.name -DistributionPointName $DP_FQDN

    $module.ExitJson()
}
