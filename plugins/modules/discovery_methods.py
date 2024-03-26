DOCUMENTATION = r'''
---
module: discovery_methods
short_description: Configure SCCM Discovery Methods.
version_added: "1.0.0"

description: Configure SCCM Discovery Methods.

options:
    site_code:
        description:
        - Site code of the SCCM deployment
        type: string
        required: true
    ludus_sccm_enable_active_directory_forest_discovery:
        description:
        - True/False whether to configure Active Directory forest discovery
        type: boolean
        required: true
    ludus_sccm_enable_active_directory_boundary_creation:
        description:
        - True/False whether to configure automatic site boundaries when they are discovered
        type: boolean
        required: true
    ludus_sccm_enable_subnet_boundary_creation:
        description:
        - True/False whether to configure automatic IP address range boundaries as they are discovered
        type: boolean
        required: true
    ludus_sccm_enable_active_directory_group_discovery:
        description:
        - True/False whether to configure Active Directory group discovery
        type: boolean
        required: true
    ludus_sccm_enable_active_directory_system_discovery:
        description:
        - True/False whether to configure Active Directory system discovery
        type: boolean
        required: true
    ludus_sccm_enable_active_directory_user_discovery:
        description:
        - True/False whether to configure Active Directory user discovery
        type: boolean
        required: true
    # HeartbeatDiscovery:
    #     description:
    #     - True/False whether to configure heartbeat discovery
    #     type: boolean
    #     required: true
    # NetworkDiscovery:
    #     description:
    #     - True/False whether to configure network discovery
    #     type: boolean
    #     required: true
        
author:
    - Zach Stein (@Synzack)
'''

EXAMPLES = r'''
- name: Configure SCCM Discovery Methods
  synzack.ludus_sccm.discovery_methods:
    site_code: "123"
    ludus_sccm_enable_active_directory_forest_discovery: true
    ludus_sccm_enable_active_directory_boundary_creation: true
    ludus_sccm_enable_subnet_boundary_creation: true
    ludus_sccm_enable_active_directory_group_discovery: true
    ludus_sccm_enable_active_directory_system_discovery: true
    ludus_sccm_enable_active_directory_user_discovery: true
'''
