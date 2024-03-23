DOCUMENTATION = r'''
---
module: clientpush
short_description: Configure SCCM Client Push Installations.
version_added: "1.0.0"

description: Configure SCCM Client Push Installations.

options:
    name:
        description: 
        - Account to set as the NAA account
        required: true
        type: string
    site_code:
        description:
        - Site code of the SCCM deployment
        type: string
        required: true
    EnableAutomaticClientPushInstallation:
        description:
        - True/False whether to install the Configuration Manager client on newly discovered computer resources
        type: boolean
        required: true
    EnableSystemTypeConfigurationManager:
        description:
        - True/False whether to install the Configuration Manager client on site system servers.
        type: boolean
        required: true
    EnableSystemTypeServer:
        description:
        - True/False whether to install the Configuration Manager client on servers.
        type: boolean
        required: true
    EnableSystemTypeWorkstation:
        description:
        - True/False whether to install the Configuration Manager client on workstations
        type: boolean
        required: true
    InstallClientToDomainController:
        description:
        - True/False whether to install the Configuration Manager client on domain controllers
        type: boolean
        required: true
    AllownNTLMFallback:
        description:
        - True/False whether to allow for fallback NTLM authentication
        type: boolean
        required: true
        
author:
    - Zach Stein (@Synzack)
'''

EXAMPLES = r'''
- name: Configure SCCM Client Push Installations
  autolabs.sccm.clientpush:
    name: 'username'
    password: 'password'
    site_code: '123'
    EnableAutomaticClientPushInstallation: true
    EnableSystemTypeConfigurationManager: true
    EnableSystemTypeServer: true
    EnableSystemTypeWorkstation: true
    InstallClientToDomainController: false
    AllownNTLMFallback: true
'''
