{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{/*
Create a default fully qualified app name.
We truncate at 40 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Although the restrictions are 63 chars in most cases, we need to reserve some more space for the suffix
of each resources, like "-conf", "-coordinator", etc. so we set 40 chars as the limit based on current implementation.
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
  {{- .Values.fullnameOverride | trunc 40 | trimSuffix "-" }}
{{- else }}
  {{- $name := default .Chart.Name .Values.nameOverride }}
  {{- if contains $name .Release.Name }}
    {{- .Release.Name | trunc 40 | trimSuffix "-" }}
  {{- else }}
    {{- printf "%s-%s" .Release.Name $name | trunc 40 | trimSuffix "-" }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "common.basePath" -}}
{{- printf "/opt/alluxio%v" . -}}
{{- end -}}

{{- define "common.baseHostPath" -}}
{{- printf "/mnt/alluxio%v" . -}}
{{- end -}}

{{- define "common.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .component }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}
{{- end -}}

{{- define "common.matchLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .component }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}
{{- end -}}

{{/* include this template with .Values instead of . */}}
{{- define "common.imagePullSecrets" -}}
imagePullSecrets:
{{- range $name := .imagePullSecrets }}
  - name: {{ $name }}
{{- end -}}
{{- end -}}

{{- define "common.volumeName" -}}
{{- $lowerKey := lower . -}}
{{- regexReplaceAll "[^-a-z0-9]+" $lowerKey "-" | trimAll "-" }}-volume
{{- end -}}

{{- define "common.volumeMounts" -}}
{{- $readOnly := .readOnly }}
{{- range $key, $val := .volumeMounts }}
- name: {{ include "common.volumeName" $key }}
  mountPath: {{ $val }}
  readOnly: {{ $readOnly }}
{{- end }}
{{- end -}}

{{- define "common.secretVolumes" -}}
{{- range $key, $val := . }}
- name: {{ include "common.volumeName" $key }}
  secret:
    secretName: {{ $key }}
    defaultMode: 256
{{- end }}
{{- end -}}

{{- define "common.configMapVolumes" -}}
{{- range $key, $val := . }}
- name: {{ include "common.volumeName" $key }}
  configMap:
    name: {{ $key }}
{{- end }}
{{- end -}}

{{- define "common.hostPathVolumes" -}}
{{- range $key, $val := . }}
- name: {{ include "common.volumeName" $key }}
  hostPath:
    path: {{ $key }}
    type: Directory
{{- end }}
{{- end -}}

{{- define "common.pvcVolumes" -}}
{{- range $key, $val := . }}
- name: {{ $key }}-volume
  persistentVolumeClaim:
    claimName: {{ $key }}
{{- end }}
{{- end -}}
