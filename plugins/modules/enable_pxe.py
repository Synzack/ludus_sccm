DOCUMENTATION = r'''
---
module: enable_pxe
short_description: Enable PXE on the Distribution Point
version_added: "1.0.0"

description: Enable PXE on the Distribution Point.

options:
    toggle_password:
        description: 
        - Name of the Operating System Image
        type: boolean
        required: true
    password:
        description:
        - Site code of the SCCM deployment
        type: string
        required: true
    site_code:
        description:
        - Site code of the SCCM deployment
        type: string
        required: true
author:
    - Zach Stein (@Synzack)
'''

EXAMPLES = r'''
- name: Add SCCM OS Image
  synzack.ludus_sccm.enable_pxe:
    toggle_password: true
    password: 'Password123'
    site_code: '123'
'''