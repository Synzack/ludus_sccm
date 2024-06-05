#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        site_code = @{ type = 'str'; required = $true }
        domain_name = @{ type = 'str'; required = $true }
        domain_account = @{ type = 'str'; required = $true }
        domain_password = @{ type = 'str'; required = $true }
        os_image = @{ type = 'str'; required = $true }

    }
    supports_check_mode = $true
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Import-Module "C:\\Program Files (x86)\\Microsoft Configuration Manager\\AdminConsole\\bin\\ConfigurationManager.psd1"
Import-Module ActiveDirectory

#https://www.windows-noob.com/forums/topic/16422-connect-configmgr64-function-to-connect-to-cmsite-sccm-feedback-for-improvement/
if ((Get-PSDrive -Name $module.Params.site_code -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
{
    $ProviderMachineName = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\ConfigMgr10\AdminUI\Connection -Name Server).Server
    New-PSDrive -Name $module.Params.site_code -PSProvider CMSite -Root $ProviderMachineName 
}

Set-Location "$($module.Params.site_code):\"

$taskExists = Get-CMTaskSequence -Name $module.Params.name 

if($taskExists) {
    $module.ExitJson()
} else {
    #Create Task Sequence
    $bootImage = Get-CMBootImage -Name "Boot image (x64)"
    $bootImageID = $bootImage.PackageID

    $osImage = Get-CMOperatingSystemImage -Name $module.Params.os_image 
    $osImageID = $osImage.PackageID

    $domainInfo = Get-ADDomain

    $workstationsOU = "OU=Workstations,"+ $domainInfo.DistinguishedName 

    $domainPassword = ConvertTo-SecureString -String $module.Params.domain_password -AsPlainText -Force 

    $clientPackage = Get-CMPackage -Name "Configuration Manager Client Package"
    $clientPackageID = $clientPackage.PackageID

    $parameters = @{
    InstallOperatingSystemImage = $true
    Name = $module.Params.name 
    Description = "Deploy PXE OS"
    BootImagePackageId = $bootImageID
    OperatingSystemImagePackageId = $osImageID 
    OperatingSystemImageIndex = 1
    HighPerformance = $true
    ConfigureBitLocker = $false
    DomainName = $module.Params.domain_name #######
    DomainAccount = $module.Params.domain_account #######
    DomainPassword = $domainPassword
    JoinDomain = "DomainType"
    DomainOrganizationUnit = "LDAP://$workstationsOU"
    ClientPackagePackageId = $clientPackageID
    GeneratePassword = $true
    }

    New-CMTaskSequence @parameters

    #Deploy Task Sequence
    $taskSequence = Get-CMTaskSequence -Name $module.Params.name 
    $taskSequenceID = $taskSequence.PackageID

    $collection = Get-CMCollection -Name "All Unknown Computers"
    $collectionID = $collection.CollectionID

    $ts_parameters = @{
        InputObject = $taskSequence
        CollectionId = $collectionID
        Availability = "MediaAndPxe"
    }

    New-CMTaskSequenceDeployment @ts_parameters

    $module.ExitJson()
}
