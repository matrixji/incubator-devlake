import pytest

from gerrit.main import GerritPlugin
from pydevlake.testing.testing import ContextBuilder


@pytest.fixture
def context():
    return (
        ContextBuilder(GerritPlugin())
        .with_connection(
            endpoint="http://10.192.1.50:8080/a/",
            username="ji_bin",
            password="Matrix123@@",
        )
        .with_scope_config()
        .with_scope(
            name="LP_LeapCloud_VehicleService",
            url="http://10.192.1.50:8080/a/LP_LeapCloud_VehicleService",
        )
        .build()
    )


def test_debug(context):
    state = {}
    stream = GerritPlugin().get_stream("gerritchanges")
    changes = list(stream.collect(state, context))
    print(len(changes))
