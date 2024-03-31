/*
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to You under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package tasks

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/apache/incubator-devlake/core/errors"
	helper "github.com/apache/incubator-devlake/helpers/pluginhelper/api"
	"github.com/apache/incubator-devlake/plugins/jenkins/models"
)

const (
	SUCCESS   = "SUCCESS"
	FAILURE   = "FAILURE"
	FAILED    = "FAILED"
	ABORTED   = "ABORTED"
	NOT_BUILD = "NOT_BUILD"
	UNSTABLE  = "UNSTABLE"
)

func ignoreHTTPStatus404(res *http.Response) errors.Error {
	if res.StatusCode == http.StatusUnauthorized {
		return errors.Unauthorized.New("authentication failed, please check your AccessToken")
	}
	if res.StatusCode == http.StatusNotFound {
		return helper.ErrIgnoreAndContinue
	}
	return nil
}

func getEnvrionmentValueFromParameters(parameters *string, defaultEnv *string) string {
	envsMapping := map[string]string{
		"prod": "PRODUCTION",
	}
	key := "deploy_env"

	// deserialize parameters
	var params []models.Parameter

	if err := json.Unmarshal([]byte(*parameters), &params); err == nil {
		for _, param := range params {
			if param.Name == key {
				valueText := fmt.Sprintf("%v", param.Value)
				if val, ok := envsMapping[valueText]; ok {
					return val
				}
				return strings.ToUpper(valueText)
			}
		}
	}
	return *defaultEnv
}
