{{- define "iter8-traffic-template.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "iter8-traffic-template.labels" -}}
  labels:
    helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "resolve.modelVersions" }}
  {{- $defaultNamespace := "modelmesh-serving" }}
  {{- $defaultWeight := ternary "100" "50" (eq .Values.trafficStrategy "mirror") }}
  {{- $defaultMatch := ternary (dict) (dict "headers" (dict "traffic" (dict "exact" "test"))) (eq .Values.trafficStrategy "canary") }}

  {{- $mV := list }}
  {{- if .Values.modelVersions }}
    {{- range $i, $ver := .Values.modelVersions }}
      {{- $v := merge $ver }}
      {{- $v = set $v "name" (default (printf "%s-%d" $.Values.modelName $i) $ver.name) }}
      {{- $v = set $v "namespace" (default $defaultNamespace $ver.namespace) }}
      {{- $v = set $v "weight" (default $defaultWeight $ver.weight) }}
      {{- $v = set $v "match" (default $defaultMatch $ver.match) }}
      {{- $mV = append $mV $v }}
    {{- end }}
  {{- else }}
    {{- $mV = append $mV (dict "name" (printf "%s-0" .Values.modelName) "namespace" $defaultNamespace "weight" $defaultWeight "match" $defaultMatch ) }}
    {{- $mV = append $mV (dict "name" (printf "%s-1" .Values.modelName ) "namespace" $defaultNamespace "weight" $defaultWeight "match" $defaultMatch ) }}
  {{- end }}
  {{- mustToJson $mV }}
{{- end }}
