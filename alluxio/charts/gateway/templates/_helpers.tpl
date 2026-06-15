{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{/*
Generate authentication and authorization config, prioritizing global config over local config
*/}}
{{- define "gateway.authConfig" -}}
{{- if and .Values.global .Values.global.authentication .Values.global.authentication.enabled -}}
{{/* Use global authentication config */}}
authentication:
  enabled: {{ .Values.global.authentication.enabled }}
  type: {{ .Values.global.authentication.type }}
  {{- with .Values.global.authentication.oidc }}
  oidc:
    {{- if .jwksUri }}
    jwksUri: {{ .jwksUri }}
    {{- end }}
    {{- if .jwksConfigMapName }}
    jwksConfigMapName: {{ .jwksConfigMapName }}
    {{- end }}
    {{- if .jwksFilename }}
    jwksFilename: {{ .jwksFilename }}
    {{- end }}
    {{- if .aud }}
    aud: {{ .aud }}
    {{- end }}
    {{- if .tid }}
    tid: {{ .tid }}
    {{- end }}
    nbfCheck: {{ .nbfCheck }}
    {{- if .roleFieldName }}
    roleFieldName: {{ .roleFieldName }}
    {{- end }}
    {{- if .groupFieldName }}
    groupFieldName: {{ .groupFieldName }}
    {{- end }}
    {{- if .userFieldName }}
    userFieldName: {{ .userFieldName }}
    {{- end }}
  {{- end }}
{{- else -}}
{{/* Use local authentication config */}}
authentication:
{{ .Values.authentication | toYaml | nindent 2 }}
{{- end }}

{{- if and .Values.global .Values.global.authorization .Values.global.authorization.enabled -}}
{{- if or (not .Values.global.authentication) (not .Values.global.authentication.enabled) -}}
{{- fail "Error: 'global.authentication.enabled' should be true when authorization is enabled" }}
{{- end -}}

{{- $globalAuthorization := .Values.global.authorization -}}
{{- $gatewayGlobalOpa := dict -}}
{{- if and $globalAuthorization.opa $globalAuthorization.opa.components $globalAuthorization.opa.components.gateway -}}
{{- $gatewayGlobalOpa = $globalAuthorization.opa.components.gateway -}}
{{- end -}}
{{/* Use global authorization config and transform it to gateway format */}}
authorization:
  enabled: {{ $globalAuthorization.enabled }}
  type: {{ $globalAuthorization.type }}
  opa:
    {{- if $gatewayGlobalOpa.configMapName }}
    configMapName: {{ $gatewayGlobalOpa.configMapName }}
    {{- end }}
    {{- if $gatewayGlobalOpa.filenames }}
    filenames: {{ $gatewayGlobalOpa.filenames | toYaml | nindent 4 }}
    {{- end }}
    {{- if $gatewayGlobalOpa.query }}
    query: {{ $gatewayGlobalOpa.query }}
    {{- end }}
    {{- if $globalAuthorization.opa.superAdmin }}
    superAdmin: {{ $globalAuthorization.opa.superAdmin | toYaml | nindent 4 }}
    {{- end }}
    {{- if $globalAuthorization.opa.groupAdmin }}
    groupAdmin: {{ $globalAuthorization.opa.groupAdmin | toYaml | nindent 4 }}
    {{- end }}
    {{- if $globalAuthorization.opa.allowApis }}
    allowApis: {{ $globalAuthorization.opa.allowApis | toYaml | nindent 4 }}
    {{- end }}
    {{- if $globalAuthorization.opa.denyApis }}
    denyApis: {{ $globalAuthorization.opa.denyApis | toYaml | nindent 4 }}
    {{- end }}
    {{- if $gatewayGlobalOpa.groups }}
    groups: {{ $gatewayGlobalOpa.groups | toYaml | nindent 4 }}
    {{- end }}
{{- else -}}
{{/* Use local authorization config */}}
authorization:
{{ .Values.authorization | toYaml | nindent 2 }}
{{- end -}}
{{- end -}}
