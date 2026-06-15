{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{/* vim: set filetype=mustache: */}}

{{/*
common.template.pvc
Creates a standard PersistentVolumeClaim.

Args:
- .name (string): The name of the PVC.
- .component (string): The component of the PVC.
- .size (string): The storage size (e.g., "1Gi").
- .storageClass (string): The storage class name.
- .accessModes (list): A list of access modes (e.g., ["ReadWriteOnce"]).
- .Values (object): Top-level values object.
- .Chart (object): Top-level chart object.
*/}}
{{- define "common.template.pvc" -}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .name }}
  labels:
    {{- include "common.labels" (dict "Chart" .Chart "Release" .Release "Values" .Values "component" .component) | nindent 4 }}
spec:
  resources:
    requests:
      storage: {{ .size }}
  storageClassName: {{ .storageClass | quote }}
  accessModes:
    {{- toYaml .accessModes | nindent 4 }}
{{- end -}}
