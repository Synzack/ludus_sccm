DOCUMENTATION = r'''
---
module: add_task_sequence
short_description: Add a task sequence to the SCCM site server
version_added: "1.0.0"

description: Add a task sequence to the SCCM site server.

options:
    name:
        description: 
        - Name of the Task Sequence
        required: true
        type: string
    site_code:
        description:
        - Site code of the SCCM deployment
        type: string
        required: true
    domain_name: 
      description:
      - Name of the domain to configure the task sequence
      type: string
      required: true
    domain_account:
      description:
      - Name of the account to join machine to the domain
      type: string
      required: true
    domain_password:
      description:
      - Password for the domain_account
      type: string
      required: true
    os_image: 
      description:
      - Name of the OS image to deploy in the task sequence
      type: string
      required: true
      
    
        
author:
    - Zach Stein (@Synzack)
'''

EXAMPLES = r'''
- name: Create OS Image Task Sequence
  synzack.ludus_sccm.add_os_task_sequence:
    name: "Windows10"
    site_code: '123'
    domain_name: 'ludus.domain'
    domain_account: 'ludus\domainadmin'
    domain_password: 'password'
    os_image: 'Windows10'
'''
