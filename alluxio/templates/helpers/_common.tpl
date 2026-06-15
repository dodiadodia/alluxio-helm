{{/* The Alluxio Open Foundation licenses this work under the Apache License, version 2.0
(the "License"). You may not use this work except in compliance with the License, which is
available at www.apache.org/licenses/LICENSE-2.0

This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied, as more fully set forth in the License.

See the NOTICE file distributed with this work for information regarding copyright ownership. */}}

{{- define "alluxio.getPvcName" -}}
{{ printf "%v-%v-pvc" .prefix .component }}
{{- end -}}

{{- define "alluxio.calculateTotalStorage" -}}
{{- $size := .size }}
{{- $inputReservedSize := .reservedSize }}
{{- $unitToBytes := dict "Ki" 1024 "Mi" 1048576 "Gi" 1073741824 "Ti" 1099511627776 "Pi" 1125899906842624 "B" 1 }}
{{- $reservedLimitBytes := mul 100 1073741824 }}

{{- $sizeValue := regexFind "[0-9]+(?:\\.[0-9]+)?" $size | float64 }}
{{- $sizeUnit := regexFind "[A-Za-z]+" $size | lower }}
{{- if or (eq $sizeUnit "k") (eq $sizeUnit "kb") (eq $sizeUnit "kib") (eq $sizeUnit "ki") }}
  {{- $sizeUnit = "Ki" }}
{{- else if or (eq $sizeUnit "m") (eq $sizeUnit "mb") (eq $sizeUnit "mib") (eq $sizeUnit "mi") }}
  {{- $sizeUnit = "Mi" }}
{{- else if or (eq $sizeUnit "g") (eq $sizeUnit "gb") (eq $sizeUnit "gib") (eq $sizeUnit "gi") }}
  {{- $sizeUnit = "Gi" }}
{{- else if or (eq $sizeUnit "t") (eq $sizeUnit "tb") (eq $sizeUnit "tib") (eq $sizeUnit "ti") }}
  {{- $sizeUnit = "Ti" }}
{{- else if or (eq $sizeUnit "p") (eq $sizeUnit "pb") (eq $sizeUnit "pib") (eq $sizeUnit "pi") }}
  {{- $sizeUnit = "Pi" }}
{{- else if or (eq $sizeUnit "b") (empty $sizeUnit) }}
  {{- $sizeUnit = "B" }}
{{- end }}
{{- $sizeInBytes := mulf $sizeValue (index $unitToBytes $sizeUnit) }}

{{- $defaultReservedBytes := min (divf $sizeInBytes 10) $reservedLimitBytes }}
{{- $ReservedGi := divf $defaultReservedBytes 1073741824 | float64 }}
{{- $resolvedReservedSize := $inputReservedSize | default (printf "%.2fB" $ReservedGi) }}

{{- $reservedValue := regexFind "[0-9]+(?:\\.[0-9]+)?" $resolvedReservedSize | float64 }}
{{- $reservedUnit := regexFind "[A-Za-z]+" $resolvedReservedSize | lower }}
{{- if or (eq $reservedUnit "k") (eq $reservedUnit "kb") (eq $reservedUnit "kib") (eq $reservedUnit "ki") }}
  {{- $reservedUnit = "Ki" }}
{{- else if or (eq $reservedUnit "m") (eq $reservedUnit "mb") (eq $reservedUnit "mib") (eq $reservedUnit "mi") }}
  {{- $reservedUnit = "Mi" }}
{{- else if or (eq $reservedUnit "g") (eq $reservedUnit "gb") (eq $reservedUnit "gib") (eq $reservedUnit "gi") }}
  {{- $reservedUnit = "Gi" }}
{{- else if or (eq $reservedUnit "t") (eq $reservedUnit "tb") (eq $reservedUnit "tib") (eq $reservedUnit "ti") }}
  {{- $reservedUnit = "Ti" }}
{{- else if or (eq $reservedUnit "p") (eq $reservedUnit "pb") (eq $reservedUnit "pib") (eq $reservedUnit "pi") }}
  {{- $reservedUnit = "Pi" }}
{{- else if or (eq $reservedUnit "b") (empty $reservedUnit) }}
  {{- $reservedUnit = "B" }}
{{- end }}
{{- $reservedInBytes := mulf $reservedValue (index $unitToBytes $reservedUnit) }}

{{- $totalInBytes := addf $sizeInBytes $reservedInBytes }}
{{- $totalInGi := divf $totalInBytes 1073741824 }}
{{- $totalInGiCeil := ceil $totalInGi | int }}
{{- printf "%dGi" $totalInGiCeil }}
{{- end }}

{{- define "alluxio.authConfig" -}}
authentication:
  {{ .Values.global.authentication | toYaml | nindent 2 }}
{{- end -}}

{{- define "alluxio.workerOidcDir" -}}
{{- include "common.basePath" "/oidc" }}
{{- end -}}

{{- define "alluxio.hostNetwork" -}}
  {{- $top := .top -}}
  {{- $componentName := .component -}}
  {{- $componentValues := index $top.Values $componentName | default dict -}}
  {{- $finalHostNetwork := false -}}
  {{- if ne $componentValues.hostNetwork nil -}}
    {{- $finalHostNetwork = $componentValues.hostNetwork -}}
  {{- else if ne $top.Values.hostNetwork nil -}}
    {{- $finalHostNetwork = $top.Values.hostNetwork -}}
  {{- end -}}
  {{- $finalHostNetwork -}}
{{- end -}}

{{- define "alluxio.dnsPolicy" -}}
  {{- $top := .top -}}
  {{- $componentName := .component -}}
  {{- $componentValues := index $top.Values $componentName | default dict -}}

  {{- $hostNetworkArgs := dict "top" $top "component" $componentName -}}
  {{- $hostNetwork := include "alluxio.hostNetwork" $hostNetworkArgs | eq "true" -}}
  {{- $fallbackDnsPolicy := ternary "ClusterFirstWithHostNet" "ClusterFirst" $hostNetwork -}}

  {{- coalesce $componentValues.dnsPolicy $top.Values.dnsPolicy $fallbackDnsPolicy -}}
{{- end -}}
