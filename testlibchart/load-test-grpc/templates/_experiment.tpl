{{ define "experiment" -}}
{{- include "iter8lib.grpc" . -}}
{{- include "iter8lib.assess" . -}}
{{ end }}