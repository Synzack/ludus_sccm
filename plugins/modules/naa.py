DOCUMENTATION = r'''
---
module: naa
short_description: Set a Network Access Account (NAA)
version_added: "1.0.0"

description: Set a Network Access Account (NAA) within an SCCM deployment.

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

author:
    - Zach Stein (@ySynzack)
'''

EXAMPLES = r'''
- name: Configure Network Access Accounts
  autolabs.sccm.naa:
    name: 'username'
    password: 'password'
    site_code: '123'
'''
