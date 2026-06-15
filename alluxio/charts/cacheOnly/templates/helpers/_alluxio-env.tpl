{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{/* vim: set filetype=mustache: */}}

{{- /* ===================================== */}}
{{- /*         CACHEONLY_JAVA_OPTS           */}}
{{- /* ===================================== */}}
{{- define "cacheonly.java.env" -}}
{{ $masterCount := int .Values.master.count }}
{{- $defaultMasterName := "master-0" }}
{{- $isSingleMaster := eq $masterCount 1 }}
{{- $fullName := include "cacheonly.fullname" . }}
{{- $alluxioJavaOpts := list }}
{{- $alluxioJavaOpts = print "-Dalluxio.gemini.license.file=/secrets/cacheonly-license/license.json" | append $alluxioJavaOpts }}
{{- /* Specify master hostname if single master */}}
{{- if $isSingleMaster }}
{{- $alluxioJavaOpts = printf "-Dalluxio.gemini.master.hostname=%v-%v" $fullName $defaultMasterName | append $alluxioJavaOpts }}
{{- end }}
{{- $alluxioJavaOpts = printf "-Dalluxio.gemini.master.journal.type=EMBEDDED" | append $alluxioJavaOpts }}
{{- $alluxioJavaOpts = printf "-Dalluxio.gemini.master.journal.folder=%v" .Values.journal.folder | append $alluxioJavaOpts }}

{{- $embeddedJournalAddresses := "-Dalluxio.gemini.master.embedded.journal.addresses=" }}
{{- range $i := until $masterCount }}
{{- $embeddedJournalAddresses = printf "%v,%v-master-%v:19200" $embeddedJournalAddresses $fullName $i }}
{{- end }}
{{- $alluxioJavaOpts = append $alluxioJavaOpts $embeddedJournalAddresses }}

{{- if .Values.jvmOptions }}
  {{- $alluxioJavaOpts = concat $alluxioJavaOpts .Values.jvmOptions }}
{{- end }}
{{- range $opt := $alluxioJavaOpts }}{{ printf "%v " $opt }}{{ end }}
{{- end -}}


{{- /* ===================================== */}}
{{- /*       CACHEONLY_MASTER_JAVA_OPTS      */}}
{{- /* ===================================== */}}
{{- define "cacheonly.master.env" -}}
{{- $masterJavaOpts := list }}
{{- $masterJavaOpts = print "-Dalluxio.gemini.master.hostname=${ALLUXIO_GEMINI_MASTER_HOSTNAME}" | append $masterJavaOpts }}
{{- if .Values.master.jvmOptions }}
  {{- $masterJavaOpts = concat $masterJavaOpts .Values.master.jvmOptions }}
{{- end }}
{{- range $opt := $masterJavaOpts }}{{ printf "%v " $opt }}{{ end }}
{{- end -}}

{{- /* ===================================== */}}
{{- /*       CACHEONLY_WORKER_JAVA_OPTS      */}}
{{- /* ===================================== */}}
{{- define "cacheonly.worker.env" -}}
{{- $workerJavaOpts := list }}
{{- $workerJavaOpts = print "-Dalluxio.gemini.worker.hostname=${ALLUXIO_GEMINI_WORKER_HOSTNAME}" | append $workerJavaOpts }}
{{- $workerJavaOpts = printf "-Dalluxio.gemini.worker.rpc.port=%v" .Values.worker.ports.rpc | append $workerJavaOpts }}
{{- $workerJavaOpts = printf "-Dalluxio.gemini.worker.web.port=%v" .Values.worker.ports.web | append $workerJavaOpts }}
{{- $workerJavaOpts = print "-Dalluxio.gemini.worker.secure.rpc.port=29997" | append $workerJavaOpts }}
{{- $workerJavaOpts = print "-Dalluxio.gemini.user.short.circuit.enabled=false" | append $workerJavaOpts }}
{{- /* Record container hostname if not using host network */}}
{{- if not .Values.worker.hostNetwork }}
  {{- $workerJavaOpts = print "-Dalluxio.gemini.worker.container.hostname=${ALLUXIO_GEMINI_WORKER_CONTAINER_HOSTNAME}" | append $workerJavaOpts }}
{{- end}}

{{- /* Resource configuration */}}
{{- if .Values.worker.resources  }}
  {{- if .Values.worker.resources.requests }}
    {{- if .Values.worker.resources.requests.memory }}
          {{- $workerJavaOpts = printf "-Dalluxio.gemini.worker.ramdisk.size=%v" .Values.worker.resources.requests.memory | append $workerJavaOpts }}
    {{- end}}
  {{- end}}
{{- end}}

{{- /* Tiered store configuration */}}
{{- if .Values.tieredstore }}
  {{- $workerJavaOpts = printf "-Dalluxio.gemini.worker.tieredstore.levels=%v" (len .Values.tieredstore.levels) | append $workerJavaOpts }}
  {{- range .Values.tieredstore.levels }}
  {{- $tierName := printf "-Dalluxio.gemini.worker.tieredstore.level%v" .level }}
    {{- if .alias }}
    {{- $workerJavaOpts = printf "%v.alias=%v" $tierName .alias | append $workerJavaOpts }}
    {{- end}}
    {{- $workerJavaOpts = printf "%v.dirs.mediumtype=%v" $tierName .mediumtype | append $workerJavaOpts }}
    {{- if .path }}
      {{- $workerJavaOpts = printf "%v.dirs.path=%v" $tierName .path | append $workerJavaOpts }}
    {{- end}}
    {{- if .quota }}
      {{- $workerJavaOpts = printf "%v.dirs.quota=%v" $tierName .quota | append $workerJavaOpts }}
    {{- end}}
    {{- if .high }}
      {{- $workerJavaOpts = printf "%v.watermark.high.ratio=%v" $tierName .high | append $workerJavaOpts }}
    {{- end}}
    {{- if .low }}
      {{- $workerJavaOpts = printf "%v.watermark.low.ratio=%v" $tierName .low | append $workerJavaOpts }}
    {{- end}}
  {{- end}}
{{- end }}

{{- if .Values.worker.jvmOptions }}
  {{- $workerJavaOpts = concat $workerJavaOpts .Values.worker.jvmOptions }}
{{- end }}
{{- range $opt := $workerJavaOpts }}{{ printf "%v " $opt }}{{ end }}
{{- end -}}

{{- define "cacheonly.env" -}}
ALLUXIO_GEMINI_JAVA_OPTS="{{ include "cacheonly.java.env" . }}"
ALLUXIO_GEMINI_MASTER_JAVA_OPTS="{{ include "cacheonly.master.env" . }}"
ALLUXIO_GEMINI_WORKER_JAVA_OPTS="{{ include "cacheonly.worker.env" . }}"
{{- end -}}
