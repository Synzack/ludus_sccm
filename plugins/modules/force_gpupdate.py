DOCUMENTATION = r'''
---
module: force_gpupdate
short_description: Force gpupdate on Certain OUs
version_added: "1.0.0"

description: Force gpupdate on Certain OUs

options:
    workstations:
        description: 
        - True/False to force gpupdate on workstations
        required: true
        type: boolean
    servers:
        description: 
        - True/False to force gpupdate on servers
        required: true
        type: boolean
    domain_controllers:
        description:
        - True/False to force gpupdate on domain controllers
        required: true
        type: boolean
        

author:
    - Zach Stein (@ySynzack)
'''

EXAMPLES = r'''
- name: Force gpupdate on OUs
  synzack.ludus_sccm.force_gpupdate:
    workstations: true
    servers: true
    domain_controllers: false
'''