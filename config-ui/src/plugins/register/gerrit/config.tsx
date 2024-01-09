/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import { DOC_URL } from '@/release';

import type { PluginConfigType } from '../../types';
import { PluginType } from '../../types';

import Icon from './assets/icon.svg';

export const GerritConfig: PluginConfigType = {
  type: PluginType.Connection,
  plugin: 'gerrit',
  name: 'Gerrit',
  icon: Icon,
  sort: 2,
  connection: {
    docLink: DOC_URL.PLUGIN.GITLAB.BASIS,
    fields: [
      'name',
      {
        key: 'endpoint',
        subLabel: 'gerrit server url'
      },
      'username',
      'password',
      'proxy',
    ],
  },
  dataScope: {
    millerColumns: {
      title: 'Projects *',
      subTitle: 'Select the project you would like to sync.',
      firstColumnTitle: 'Subgroups/Projects',
    },
  },
  scopeConfig: {
    entities: ['CODE', 'CODEREVIEW'],
    transformation: {
      refdiff: {
        tagsLimit: 10,
        tagsPattern: '/v\\d+\\.\\d+(\\.\\d+(-rc)*\\d*)*$/',
      },
    },
  },
};
