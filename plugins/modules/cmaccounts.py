DOCUMENTATION = r'''
---
module: cmaccounts
short_description: Add a Domain User as a CM Account
version_added: "1.0.0"

description: Add a Domain User as a CM Account

options:
    name:
        description: 
        - Account to add as a CM Account
        required: true
        type: string
    password:
        description: 
        - Password for the CM Account
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
- name: Configure CM Accounts
  synzack.ludus_sccm.cmaccounts:
    name: 'domain\username'
    password: 'password'
    site_code: '123'
'''
