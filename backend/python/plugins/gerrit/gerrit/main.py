import logging
from typing import Iterable
from urllib.parse import urlparse
from gerrit.streams.changes import GerritChanges
from gerrit.streams.change_commits import GerritChangeCommits
from gerrit.api import GerritApi

from gerrit.models import GerritConnection, GerritProject, GerritProjectConfig

import pydevlake as dl
from pydevlake.api import APIException
from pydevlake.domain_layer.code import Repo
from pydevlake.message import PipelineTask, RemoteScopeGroup, TestConnectionResult, RemoteScope
from pydevlake.model import Connection, DomainScope, DomainType, ScopeConfig, raw_data_params
from pydevlake.pipeline_tasks import gitextractor, refdiff
from pydevlake.plugin import Plugin, ScopeConfigPair
from pydevlake.stream import Stream


logger = logging.getLogger()

class GerritPlugin(Plugin):

    @property
    def connection_type(self):
        return GerritConnection

    @property
    def tool_scope_type(self):
        return GerritProject

    @property
    def scope_config_type(self):
        return GerritProjectConfig

    def domain_scopes(self, gerrit_project: GerritProject):
        yield Repo(
            name=gerrit_project.name,
            url=gerrit_project.url,
        )

    def remote_scope_groups(self, connection: Connection) -> list[RemoteScopeGroup]:
        yield RemoteScopeGroup(
            id=f'{connection.id}:default',
            name='Code Repositories',
        )

    def remote_scopes(self, connection: Connection, group_id: str) -> list[GerritProject]:
        api = GerritApi(connection)
        json_data = api.projects().json
        for project_name in json_data:
            yield GerritProject(
                id=project_name,
                name=project_name,
                url=connection.url + project_name,
            )

    def test_connection(self, connection: Connection):
        api = GerritApi(connection)
        message = None
        try:
            res = api.projects()
        except APIException as e:
            res = e.response
            message = 'HTTP Error: ' + str(res.status)
        return TestConnectionResult.from_api_response(res, message)

    def extra_tasks(self, scope: GerritProject, config: ScopeConfig, connection: GerritConnection) -> list[PipelineTask]:
        if DomainType.CODE in config.domain_types:
            url = urlparse(scope.url)
            if connection.username and connection.password:
                url = url._replace(netloc=f'{connection.username}:{connection.password.get_secret_value()}@{url.netloc}')
            yield gitextractor(url.geturl(), scope.name, scope.domain_id(), connection.proxy)

    def extra_stages(self, scope_config_pairs: list[tuple[GerritProject, ScopeConfig]], connection: GerritConnection) -> list[list[PipelineTask]]:
        for scope, config in scope_config_pairs:
            if DomainType.CODE in config.domain_types:
                yield [refdiff(scope.id, config.refdiff)]

    @property
    def streams(self) -> list[Stream]:
        return [
            GerritChanges,
            GerritChangeCommits,
        ]


if __name__ == '__main__':
    GerritPlugin.start()
