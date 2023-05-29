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

import { useEffect, useState } from 'react';
import { useHistory } from 'react-router-dom';
import { InputGroup, Checkbox, Button, Intent } from '@blueprintjs/core';

import { Card, FormItem, Buttons, toast } from '@/components';
import { operator } from '@/utils';

import type { ProjectType } from '../types';
import { validName } from '../utils';

import * as API from './api';

interface Props {
  project: ProjectType;
}

export const SettingsPanel = ({ project }: Props) => {
  const [name, setName] = useState('');
  const [enableDora, setEnableDora] = useState(false);
  const [operating, setOperating] = useState(false);

  const history = useHistory();

  useEffect(() => {
    const doraMetrics = project.metrics.find((ms: any) => ms.pluginName === 'dora');

    setName(project.name);
    setEnableDora(doraMetrics?.enable ?? false);
  }, [project]);

  const handleUpdate = async () => {
    if (!validName(name)) {
      toast.error('Please enter alphanumeric or underscore');
      return;
    }

    const [success] = await operator(
      () =>
        API.updateProject(project.name, {
          name,
          description: '',
          metrics: [
            {
              pluginName: 'dora',
              pluginOption: '',
              enable: enableDora,
            },
          ],
        }),
      {
        setOperating,
      },
    );

    if (success) {
      history.push(`/projects/${name}`);
    }
  };

  return (
    <Card>
      <FormItem label="Project Name" subLabel="Edit your project name with letters, numbers, -, _ or /" required>
        <InputGroup style={{ width: 386 }} value={name} onChange={(e) => setName(e.target.value)} />
      </FormItem>
      <FormItem subLabel="DORA metrics are four widely-adopted metrics for measuring software delivery performance.">
        <Checkbox
          label="Enable DORA Metrics"
          checked={enableDora}
          onChange={(e) => setEnableDora((e.target as HTMLInputElement).checked)}
        />
      </FormItem>
      <Buttons>
        <Button text="Save" loading={operating} disabled={!name} intent={Intent.PRIMARY} onClick={handleUpdate} />
      </Buttons>
    </Card>
  );
};