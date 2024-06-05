DOCUMENTATION = r'''
---
module: add_os_image
short_description: Add an operating system image to the SCCM site server
version_added: "1.0.0"

description: Configure SCCM Operating system Images.

options:
    name:
        description: 
        - Name of the Operating System Image
        required: true
        type: string
    site_code:
        description:
        - Site code of the SCCM deployment
        type: string
        required: true
    path:
      description:
      - Network path of the OS image WIM file
      type: string
      required: true
    
        
author:
    - Zach Stein (@Synzack)
'''

EXAMPLES = r'''
- name: Add SCCM OS Image
  synzack.ludus_sccm.add_os_image:
    name: "Windows10"
    path: "\\sccm-sitesrv.ludus.domain\sms_123\OSD\Images\win10.wim"
    site_code: '123'
'''
