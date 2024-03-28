# SCCM Collection for Ansible and [Ludus](ludus.cloud)

This collection includes Ansible roles to install and configure SCCM. For a good example of the collection's usage, see the `sccm-range-config.yml`.

Roles included in this collection:

  - `synzack.ludus_sccm.disable_firewall` 
  - `synzack.ludus_sccm.ludus_sccm_distro`
  - `synzack.ludus_sccm.ludus_sccm_mgmt`
  - `synzack.ludus_sccm.ludus_sccm_siteserver`
  - `synzack.ludus_sccm.ludus_sccm_sql`

## Installation in [Ludus](ludus.cloud)

Install via Ansible Galaxy:

```
ludus ansible collection add synzack.ludus_sccm
```

### Role Requirements

None

## Usage

> [!WARNING]
> All SCCM VM hostnames MUST be <= 15 characters

![SCCM Netbios Limitation](./sccm_netbios_limit.png)

Here's an example Ludus configuration that uses this module to set up a full SCCM deployment:

```yaml
ludus:
  - vm_name: "{{ range_id }}-DC01"
    hostname: "{{ range_id }}-DC01"
    template: win2022-server-x64-template
    vlan: 10
    ip_last_octet: 10
    ram_gb: 4
    cpus: 2
    windows:
      sysprep: true
    domain:
      fqdn: ludus.domain
      role: primary-dc

  - vm_name: "{{ range_id }}-Workstation"
    hostname: "{{ range_id }}-Workstation"
    template: win11-22h2-x64-enterprise-template
    vlan: 10
    ip_last_octet: 11
    ram_gb: 4
    cpus: 2
    windows:
      sysprep: true
    domain:
      fqdn: ludus.domain
      role: member
    roles:
      - synzack.ludus_sccm.disable_firewall

  - vm_name: "{{ range_id }}-sccm-distro"
    hostname: "sccm-distro"
    template: win2022-server-x64-template
    vlan: 10
    ip_last_octet: 12
    ram_gb: 8
    cpus: 4
    windows:
      sysprep: true
    domain:
      fqdn: ludus.domain
      role: member
    roles:
      - synzack.ludus_sccm.ludus_sccm_distro
    role_vars:
      ludus_sccm_site_server_hostname: '{{ range_id }}-sccm-sitesrv' # Default = 'sccm-sitesrv'

  - vm_name: "{{ range_id }}-sccm-sql"
    hostname: "sccm-sql" # MUST BE < 15 characters! SCCM requirement
    template: win2022-server-x64-template
    vlan: 10
    ip_last_octet: 13
    ram_gb: 8
    cpus: 4
    windows:
      sysprep: true
    domain:
      fqdn: ludus.domain
      role: member
    roles:
      - synzack.ludus_sccm.ludus_sccm_sql
    role_vars:
      ludus_sccm_site_server_hostname: 'sccm-sitesrv'    # Default = 'sccm-sitesrv' MUST BE < 15 characters! SCCM requirement
      ludus_sccm_sql_server_hostname: 'sccm-sql'         # Default = 'sccm-sql'     MUST BE < 15 characters! SCCM requirement
      ludus_sccm_sql_svc_account_username: 'sqlsccmsvc'  # Default = 'sqlsccmsvc'   MUST BE < 15 characters! SCCM requirement
      ludus_sccm_sql_svc_account_password: 'Password123' # Default = 'Password123' - Must Meet Complexity Requirements

  - vm_name: "{{ range_id }}-sccm-mgmt"
    hostname: "sccm-mgmt" # MUST BE < 15 characters! SCCM requirement
    template: win2022-server-x64-template
    vlan: 10
    ip_last_octet: 14
    ram_gb: 8
    cpus: 4
    windows:
      sysprep: true
    domain:
      fqdn: ludus.domain
      role: member
    roles:
      - synzack.ludus_sccm.ludus_sccm_mgmt
    role_vars:
      ludus_sccm_site_server_hostname: "sccm-sitesrv" # Default = 'sccm-sitesrv'

  - vm_name: "{{ range_id }}-sccm-sitesrv"
    hostname: "sccm-sitesrv" # If changed, you need to update the "ludus_sccm_site_server_hostname" variables in this config. MUST BE < 15 characters! SCCM requirement
    template: win2022-server-x64-template
    vlan: 10
    ip_last_octet: 15
    ram_gb: 8
    cpus: 4
    windows:
      sysprep: true
    domain:
      fqdn: ludus.domain
      role: member
    roles:
      - synzack.ludus_sccm.ludus_sccm_siteserver
    role_vars:
      ludus_sccm_sitecode: 123           # Default = 123 - Must be a 3 character string (upper case and numbers allowed)
      ludus_sccm_sitename: Primary Site  # Default = Primary Site
      ludus_sccm_site_server_hostname: 'sccm-sitesrv'  # Default = 'sccm-sitesrv' MUST BE < 15 characters! SCCM requirement
      ludus_sccm_distro_server_hostname: 'sccm-distro' # Default = 'sccm-distro'  MUST BE < 15 characters! SCCM requirement
      ludus_sccm_mgmt_server_hostname: 'sccm-mgmt'     # Default = 'sccm-mgmt'    MUST BE < 15 characters! SCCM requirement
      ludus_sccm_sql_server_hostname: 'sccm-sql'       # Default = 'sccm-sql'     MUST BE < 15 characters! SCCM requirement
      # --------------------------NAA Account-------------------------------------------------
      ludus_sccm_configure_nna: true
      ludus_sccm_nna_username: 'sccm_naa'
      ludus_sccm_nna_password: 'Password123'
      # --------------------------Client Push Account-----------------------------------------
      ludus_sccm_configure_client_push: true
      ludus_sccm_client_push_username: 'sccm_push'
      ludus_sccm_client_push_password: 'Password123'
      ludus_sccm_enable_automatic_client_push_installation: true
      ludus_sccm_enable_system_type_configuration_manager: true
      ludus_sccm_enable_system_type_server: true
      ludus_sccm_enable_system_type_workstation: true
      ludus_sccm_install_client_to_domain_controller: false
      ludus_sccm_allow_NTLM_fallback: true
      # --------------------------Task Sequence Account---------------------------------------
      ludus_sccm_configure_task_sequence: true
      ludus_sccm_task_sequence_username: 'sccm_task'
      ludus_sccm_task_sequence_password: 'Password123'
      # --------------------------Task Sequence - Domain Join Account-------------------------
      ludus_sccm_configure_domain_join: true
      ludus_sccm_domain_join_username: 'sccm_domainjoin'
      ludus_sccm_domain_join_password: 'Password123'
      # ---------------------------Discovery Methods------------------------------------------
      ludus_sccm_enable_active_directory_forest_discovery: true
      ludus_sccm_enable_active_directory_boundary_creation: true
      ludus_sccm_enable_subnet_boundary_creation: true
      ludus_sccm_enable_active_directory_group_discovery: true
      ludus_sccm_enable_active_directory_system_discovery: true
      ludus_sccm_enable_active_directory_user_discovery: true
      # -----------------------------ludus_sccm_pushover-------------------------------------------------
      ludus_sccm_pushover: false                     # Default = false
      ludus_sccm_pushover_msg: 'Lab Setup Complete'  # Default = 'Lab Setup Complete'
      ludus_sccm_pushover_app_token: ''              # Default = ''
      ludus_sccm_pushover_user_key: ''               # Default = ''

```

Then set the config and deploy it

```
ludus range config set -f sccm-range-config.yml
ludus range deploy
```

## Building the Collection from Source

```
git clone https://github.com/Synzack/Ludus-Autolabs
ansible-galaxy collection build
```

### Ludus Install of manually built collection

via Ludus ansible collection
```
python3 -m http.server 80
ludus ansible collection add http://<network ip>/synzack-ludus_sccm-1.0.0.tar.gz
```

via scp
```
export LUDUS_USER_NANE=$(ludus user list --json | jq -r '.[].proxmoxUsername')
ssh root@<ludus-host> "mkdir -r /opt/ludus/users/$LUDUS_USER_NANE/.ansible/collections/ansible_collections/synzack/ludus_sccm"
rsync -av --exclude .git/ ./ root@<ludus-host>:/opt/ludus/users/$LUDUS_USER_NANE/.ansible/collections/ansible_collections/synzack/ludus_sccm/
```

## License

GPLv3

## Author

This collection was created by [Zach Stein](https://twitter.com/synzack21) and (Erik Hunstad)[https://github.com/kernel-sanders], for [Ludus](ludus.cloud).
