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
    ludus_sccm_enable_automatic_client_push_installation:
        description:
        - True/False whether to install the Configuration Manager client on newly discovered computer resources
        type: boolean
        required: true
    ludus_sccm_enable_system_type_configuration_manager:
        description:
        - True/False whether to install the Configuration Manager client on site system servers.
        type: boolean
        required: true
    ludus_sccm_enable_system_type_server:
        description:
        - True/False whether to install the Configuration Manager client on servers.
        type: boolean
        required: true
    ludus_sccm_enable_system_type_workstation:
        description:
        - True/False whether to install the Configuration Manager client on workstations
        type: boolean
        required: true
    ludus_sccm_install_client_to_domain_controller:
        description:
        - True/False whether to install the Configuration Manager client on domain controllers
        type: boolean
        required: true
    ludus_sccm_allow_NTLM_fallback:
        description:
        - True/False whether to allow for fallback NTLM authentication
        type: boolean
        required: true
        
author:
    - Zach Stein (@Synzack)
'''

EXAMPLES = r'''
- name: Configure SCCM Client Push Installations
  synzack.ludus_sccm.clientpush:
    name: 'username'
    password: 'password'
    site_code: '123'
    ludus_sccm_enable_automatic_client_push_installation: true
    ludus_sccm_enable_system_type_configuration_manager: true
    ludus_sccm_enable_system_type_server: true
    ludus_sccm_enable_system_type_workstation: true
    ludus_sccm_install_client_to_domain_controller: false
    ludus_sccm_allow_NTLM_fallback: true
'''
