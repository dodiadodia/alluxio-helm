{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{/* vim: set filetype=mustache: */}}

{{- /* ===================================== */}}
{{- /*       ALLUXIO_COORDINATOR_JAVA_OPTS        */}}
{{- /* ===================================== */}}
{{- define "alluxio.coordinator.env" -}}
{{- $coordinatorJavaOpts := list }}
{{- $fullName := include "common.fullname" . }}
{{- $headlessServiceName := print $fullName "-coordinator" }}
{{- $coordinatorJavaOpts = print "-Dalluxio.coordinator.hostname=${HOSTNAME}." $headlessServiceName | append $coordinatorJavaOpts }}
{{- if .Values.coordinator.jvmOptions }}
  {{- $coordinatorJavaOpts = concat $coordinatorJavaOpts .Values.coordinator.jvmOptions }}
{{- end }}
{{- range $opt := $coordinatorJavaOpts }}{{ printf "%v " $opt }}{{ end }}
{{- end -}}

{{- /* ===================================== */}}
{{- /*       ALLUXIO_WORKER_JAVA_OPTS        */}}
{{- /* ===================================== */}}
{{- define "alluxio.worker.env" -}}
{{- $workerConfig := .workerConfig | default .Values.worker -}}
{{- $workerJavaOpts := list
    "-Dalluxio.worker.hostname=${ALLUXIO_WORKER_HOSTNAME}"
    "-Dalluxio.node.label=${ALLUXIO_NODE_LABEL}"
}}
{{- if .Values.worker.useExternalId }}
  {{- $workerJavaOpts = append $workerJavaOpts "-Dalluxio.worker.identity.external=${HOSTNAME}" }}
{{- end }}
{{- if $workerConfig.jvmOptions }}
  {{- $workerJavaOpts = concat $workerJavaOpts $workerConfig.jvmOptions }}
{{- end }}
{{- range $opt := $workerJavaOpts }}{{ printf "%v " $opt }}{{ end }}
{{- end -}}

{{- define "alluxio.env" -}}
ALLUXIO_COORDINATOR_JAVA_OPTS="{{ include "alluxio.coordinator.env" . }}"
ALLUXIO_WORKER_JAVA_OPTS="{{ include "alluxio.worker.env" . }}"
ALLUXIO_FUSE_BUILTIN_OPTS="-Dalluxio.user.hostname=${ALLUXIO_CLIENT_HOSTNAME} -Dalluxio.node.label=${ALLUXIO_NODE_LABEL}"
ALLUXIO_FUSE_JVM_OPTS="${ALLUXIO_FUSE_JVM_OPTS:-{{- range .Values.fuse.jvmOptions }}{{ . }} {{ end }}}"
ALLUXIO_FUSE_JAVA_OPTS="${ALLUXIO_FUSE_BUILTIN_OPTS} ${ALLUXIO_FUSE_JVM_OPTS}"
{{- end -}}
