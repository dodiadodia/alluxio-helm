{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{/* vim: set filetype=mustache: */}}

{{/*
common.template.service
Creates a standard Service.

Args:
- .name (string): The name of the Service.
- .namespace (string, optional): The namespace of the Service.
- .component (string): The component of the Service for labels.
- .serviceValues (object): The service configuration block from values.yaml (e.g., .Values.service or .Values.console.service).
- .selector (map, optional): The selector for the service. Defaults to common.matchLabels.
- .Values (object): Top-level values object.
- .Chart (object): Top-level chart object.
- .Release (object): Top-level release object.
*/}}
{{- define "common.template.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  {{- if .namespace }}
  namespace: {{ .namespace }}
  {{- end }}
  labels:
    {{- include "common.labels" (dict "component" .component "Chart" .Chart "Release" .Release "Values" .Values) | nindent 4 }}
  {{- if .serviceValues.annotations }}
  annotations:
    {{- toYaml .serviceValues.annotations | nindent 4 }}
  {{- end }}
spec:
  type: {{ .serviceValues.type | default "ClusterIP" }}
  ports:
    {{- range $key, $val := .serviceValues.ports }}
    - port: {{ $val }}
      name: {{ $key }}
      {{- if eq $.serviceValues.type "NodePort" }}
      nodePort: {{ index $.serviceValues.nodePorts $key }}
      {{- end }}
    {{- end }}
  {{- if and (or (not .serviceValues.type) (eq .serviceValues.type "ClusterIP")) .serviceValues.headless }}
  clusterIP: None
  {{- end }}
  {{- if eq .serviceValues.type "ExternalName" }}
  externalName: {{ .serviceValues.externalName }}
  {{- else }}
  {{- if eq .serviceValues.type "LoadBalancer" }}
  loadBalancerSourceRanges:
    {{- toYaml .serviceValues.loadBalancerSourceRanges | nindent 4 }}
  {{- end }}
  {{- if .serviceValues.externalIPs }}
  externalIPs:
    {{- toYaml .serviceValues.externalIPs | nindent 4 }}
  {{- end }}
  selector:
    {{- include "common.matchLabels" (dict "component" .component "Release" .Release "Chart" .Chart "Values" .Values) | nindent 4 }}
    {{- if .selector }}
    {{- toYaml .selector | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end -}}
