{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{/* vim: set filetype=mustache: */}}

{{- define "alluxio.site.properties" -}}
{{- $workerConfig := .workerConfig | default .Values.worker }}
{{- $properties := .properties | default .Values.properties -}}
# Presets
alluxio.k8s.env.deployment=true
alluxio.cluster.name={{ .Release.Namespace }}-{{ .Release.Name }}
{{- if .Values.etcd.enabled }}
alluxio.etcd.endpoints={{ printf "http://%v-etcd.%v:%v" .Release.Name .Release.Namespace .Values.etcd.service.ports.client }}
{{- end }}
{{- if .Values.fdb.enabled }}
{{- $fdbDirPath := include "common.basePath" "/fdb" }}
alluxio.foundationdb.cluster.file.path={{ $fdbDirPath }}/fdb.cluster
{{- end }}
alluxio.user.metadata.cache.max.size=0
alluxio.worker.page.store.page.size=4MB

{{- $authConfig := include "alluxio.authConfig" . | fromYaml }}
{{- if and $authConfig.authentication.enabled (eq $authConfig.authentication.type "oidc") }}
  {{- if $authConfig.authentication.oidc.jwksUri }}
alluxio.security.authentication.token.external.jwksaddr={{ $authConfig.authentication.oidc.jwksUri }}
  {{- else if and $authConfig.authentication.oidc.jwksConfigMapName $authConfig.authentication.oidc.jwksFilename }}
alluxio.security.authentication.token.external.jwksaddr=file://{{ include "alluxio.workerOidcDir" . }}/{{ $authConfig.authentication.oidc.jwksFilename }}
  {{- end }}
  {{- if and $authConfig.authentication.oidc.userFieldName }}
alluxio.security.authentication.token.assume.user.field={{ $authConfig.authentication.oidc.userFieldName }}
  {{- end }}
  {{- if and $authConfig.authentication.oidc.groupFieldName }}
alluxio.security.authentication.token.assume.group.field={{ $authConfig.authentication.oidc.groupFieldName }}
  {{- end }}
  {{- if and $authConfig.authentication.oidc.roleFieldName }}
alluxio.security.authentication.token.assume.role.field={{ $authConfig.authentication.oidc.roleFieldName }}
  {{- end }}
  {{- if and $authConfig.authentication.oidc.aud }}
alluxio.security.authentication.token.aud={{ $authConfig.authentication.oidc.aud }}
  {{- end }}
  {{- if and $authConfig.authentication.oidc.tid }}
alluxio.security.authentication.token.tid={{ $authConfig.authentication.oidc.tid }}
  {{- end }}
  {{- if $authConfig.authentication.oidc.nbfCheck }}
alluxio.security.authentication.token.nbf.check={{ $authConfig.authentication.oidc.nbfCheck }}
  {{- end }}
{{- end }}

# Custom properties
{{- range $key, $val := $properties }}
{{ printf "%v=%v" $key $val }}
{{- end }}

# Auto-generated metadata
alluxio.coordinator.hostname={{ include "common.fullname" . }}-coordinator-svc.{{ .Release.Namespace }}
alluxio.coordinator.metastore.dir={{ include "common.baseHostPath" "/metastore" }}
{{- if and (gt (int .Values.coordinator.count) 1) (not (hasKey $properties "alluxio.coordinator.job.meta.store.type")) }}
alluxio.coordinator.job.meta.store.type=ETCD
{{- end }}
alluxio.dora.worker.metastore.rocksdb.dir={{ include "common.baseHostPath" "/metastore" }}
alluxio.worker.identity.uuid.file.path={{ printf "%v/worker_identity" (include "common.baseHostPath" "/system-info") }}
alluxio.worker.page.store.dirs=
{{- range $i, $size := splitList "," $workerConfig.pagestore.size }}
  {{- if $i -}},{{- end -}}
  {{- include "common.baseHostPath" (printf "/pagestore-%d" $i) -}}
{{- end }}
alluxio.worker.page.store.sizes={{ $workerConfig.pagestore.size }}

{{- if and $workerConfig.pagestore.reservedSize (ne $workerConfig.pagestore.reservedSize "null") }}
alluxio.worker.page.store.reserved.size={{ $workerConfig.pagestore.reservedSize }}
{{- end }}

{{- if eq (index $properties "alluxio.fuse.non.disruptive.migration.enabled") "true" }}
{{- $migrationDir := include "common.baseHostPath" "/migration" }}
alluxio.fuse.non.disruptive.migration.state.file.directory.path={{ include "common.baseHostPath" "/migration" }}
{{- end }}

# Hardcoded presets
alluxio.mount.table.source=ETCD

{{- if .Values.cacheOnly.enabled }}
{{/*The default user in cacheOnly is "alluxio". When a client writes data, */}}
{{/*an error occurs because the user is not using the "alluxio" user. */}}
{{/*This configuration ensures that the user is "alluxio".*/}}
# gemini
alluxio.gemini.security.login.username=alluxio
{{- end }}

{{- end -}}
