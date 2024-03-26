DOCUMENTATION = r'''
---
module: create_boundary_group
short_description: Configure and Create SCCM Boundary Groups
version_added: "1.0.0"

description: Configure and Create SCCM Boundary Groups.

options:
    site_code:
        description:
        - Site code of the SCCM deployment
        type: string
        required: true
    boundary_group_name:
        description: 
        - Name for the boundary group
        required: true
        type: string
    boundary_group_description:
        description:
        - Description for the boundary group
        type: string
        required: true
    site_system_server_names:
        description: 
        - FQDNs of site system servers to add to the boundary group
        type: list
        required: true
    boundary:
        description:
        - Boundary to connect to the boundary group
        type: string
        required: true
        
author:
    - Zach Stein (@Synzack)
'''

EXAMPLES = r'''
- name: Create Boundary Group
  synzack.ludus_sccm.create_boundary_group:
    site_code: 123
    boundary_group_name: Default
    boundary_group_description: Default Description
    site_system_server_names:
    - test
    boundary: "contoso.local/Default-First-Site-Name"
       
'''