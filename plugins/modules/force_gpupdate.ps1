#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        workstations = @{ type = 'bool'; required = $true }
        servers = @{ type = 'bool'; required = $true }
        domain_controllers = @{ type = 'bool'; required = $true }
    }
    supports_check_mode = $true
}
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Import-Module ActiveDirectory

$domainInfo = Get-ADDomain

# Define the search base where servers are located (e.g., an Organizational Unit)
$serversOU = "OU=servers,"+ $domainInfo.DistinguishedName
$workstationsOU = "OU=Workstations,"+ $domainInfo.DistinguishedName 

# Get all servers within the specified search base
$servers = Get-ADComputer -Filter * -SearchBase $serversOU
$workstations = Get-ADComputer -Filter * -SearchBase $workstationsOU

# Get all domain controllers
$domainControllers = Get-ADDomainController -Filter *

#Force gpupdate
if($module.Params.workstations){
    foreach ($workstation in $workstations) {
        Invoke-GPUpdate -Computer $workstation.Name -Force -RandomDelayInMinutes 0 
    } 
}

if($module.Params.servers){
    foreach ($server in $servers) {
        Invoke-GPUpdate -Computer $server.Name -Force -RandomDelayInMinutes 0 
    } 
}

if($module.Params.domain_controllers){
    foreach ($domainController in $domainControllers) {
        Invoke-GPUpdate -Computer $domainController.Name -Force -RandomDelayInMinutes 0 
    } 
}

$module.ExitJson()
