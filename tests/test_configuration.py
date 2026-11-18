from pathlib import Path
import pytest
import yaml
from ansible.parsing.dataloader import DataLoader
from ansible.template import Templar

ROOT = Path(__file__).resolve().parents[1]
ROLE = ROOT / 'roles/ludus_sccm_siteserver'
DEFAULTS = yaml.safe_load((ROLE / 'defaults/main.yml').read_text())

def render(text, **overrides):
    variables = dict(DEFAULTS, ludus_domain_fqdn='corp.example.test', **overrides)
    return Templar(loader=DataLoader(), variables=variables).template(text)

def test_release_cache_isolated_from_old_same_named_bootstrappers():
    tasks = yaml.safe_load((ROLE / 'tasks/download_file.yml').read_text())
    cached = tasks[1]['ansible.builtin.get_url']['dest']
    old = '/opt/ludus/resources/sccm/adksetup.exe'
    new = render(cached, ludus_install_directory='/opt/ludus', ludus_sccm_file_name='adksetup.exe', ludus_sccm_cache_namespace='adk-10.1.26100.9457')
    assert new != old
    assert new == '/opt/ludus/resources/sccm/adk-10.1.26100.9457/adksetup.exe'

@pytest.mark.parametrize('proxy', [None, False, True])
def test_answer_file_supports_scp_with_optional_proxy(proxy):
    overrides = {'ludus_sccm_scp_proxy_name': 'proxy.corp.example.test'}
    if proxy is not None:
        overrides['ludus_sccm_scp_use_proxy'] = proxy
    result = render((ROLE / 'templates/ConfigMgrSetup.ini.j2').read_text(), **overrides)
    expected_proxy = proxy is True
    import configparser
    ini = configparser.ConfigParser()
    ini.read_string(result)
    assert ini['CloudConnectorOptions']['CloudConnector'] == '1'
    assert ini['CloudConnectorOptions']['UseProxy'] == str(int(expected_proxy))
    assert ('ProxyName' in ini['CloudConnectorOptions']) == expected_proxy
    assert ('ProxyPort' in ini['CloudConnectorOptions']) == expected_proxy
    assert ini['SQLConfigOptions']['SQLServerName'] == 'sccm-sql.corp.example.test'
    assert ini['Options']['ProductID'] == 'EVAL'
    assert ini['Options']['RoleCommunicationProtocol'] == 'HTTPorHTTPS'

@pytest.mark.parametrize('code,valid', [(123, True), ('ABC', True), ('ABCDE', False), ('A;B', False)])
def test_site_code_validation_accepts_existing_numeric_config(code, valid):
    expression = "{{ ludus_sccm_sitecode | string is match('^[A-Za-z0-9]{3}$') }}"
    assert render(expression, ludus_sccm_sitecode=code) is valid

def test_explicit_iso_override_on_local_storage():
    tasks = yaml.safe_load((ROLE / 'tasks/config_pxe.yaml').read_text())
    custom = next(task for task in tasks if task['name'] == 'Copy ISO file to Site Server from custom path')
    variables = dict(proxmox_iso_storage_pool='local', ludus_sccm_win11_iso_path='/isos/custom.iso', file_host_check={'stat': {'exists': False}})
    assert all(render('{{ ' + condition + ' }}', **variables) for condition in custom['when'])


def test_offline_payload_cache_tracks_iso_contents():
    tasks = yaml.safe_load((ROLE / 'tasks/windows_feature_source.yml').read_text())
    block = tasks[1]['block']
    facts = next(task['ansible.builtin.set_fact'] for task in block if 'ansible.builtin.set_fact' in task)
    template = facts['sccm_windows_source_cache']
    first = render(template, ludus_install_directory='/opt/ludus', sccm_windows_iso={'stat': {'checksum': 'a' * 64}})
    second = render(template, ludus_install_directory='/opt/ludus', sccm_windows_iso={'stat': {'checksum': 'b' * 64}})
    assert first != second
    assert first.endswith('/windows-aaaaaaaaaaaa')


def test_password_bearing_account_loops_suppress_item_output():
    tasks = yaml.safe_load((ROLE / 'tasks/cm_accounts.yml').read_text())
    for task in tasks:
        assert task.get('no_log') is True, task['name']
