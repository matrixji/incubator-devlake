

from os import environ
from gerrit.models import GerritConnection, GerritProjectConfig
from gerrit.main import GerritPlugin
from pydevlake.testing import assert_valid_plugin
from pydevlake.testing.testing import assert_plugin_run


def test_valid_plugin():
    assert_valid_plugin(GerritPlugin())

def test_valid_plugin_and_connection():
    connection_name = "test_connection"
    connection_url = environ.get('GERRIT_URL', 'https://gerrit.onap.org/r/')
    connection_username = environ.get('GERRIT_USERNAME', '')
    connection_password = environ.get('GERRIT_PASSWORD', '')
    plugin = GerritPlugin()
    connection = GerritConnection(
        name=connection_name,
        base_url=connection_url,
        username=connection_username,
        password=connection_password)
    scope_config = GerritProjectConfig(id=1, name='test_config')
    assert_plugin_run(plugin, connection, scope_config)

def test_debug():
    connection_name = "test_connection"
    connection_url = environ.get('GERRIT_URL', 'http://10.192.1.50:8080/a/')
    connection_username = environ.get('GERRIT_USERNAME', 'ji_bin')
    connection_password = environ.get('GERRIT_PASSWORD', 'Matrix123@@')
    plugin = GerritPlugin()
    connection = GerritConnection(
        name=connection_name,
        base_url=connection_url,
        username=connection_username,
        password=connection_password,
        pattern='LP_.*')
    scope_config = GerritProjectConfig(id=1, name='test_config')
    assert_plugin_run(plugin, connection, scope_config)