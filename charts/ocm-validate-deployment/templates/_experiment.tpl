{{ define "experiment" -}}
# task 1: determine number of failed deployments (error-count) and ratio of expected (error-rate)
# Generates the ocm/error-count and ocm/error-rate metrics.
- task: ocm-validate-deployment
  with:
    appBundle: {{ required "A valid AppBundle name is required!" .Values.appBundle}}
    {{- if .Values.timeout }}
    timeout: {{ .Values.timeout}}
    {{- end }}

{{- if .Values.SLOs }}
# task 2: validate service level objectives for app using
# the metrics collected in the above task
- task: assess-app-versions
  with:
    SLOs:
    {{- range $key, $value := .Values.SLOs }}
    {{- if or (regexMatch "error-rate" $key) (regexMatch "error-count" $key) }}
    - metric: "{{ $key }}"
      upperLimit: {{ $value }}
    {{- else }}
    {{- fail "Invalid SLO metric specified" }}
    {{- end }}
    {{- end }}
{{- end }}
{{ end }}
