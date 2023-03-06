{{- define "task.http" -}}
{{- /* Validate values */ -}}
{{- if not . }}
{{- fail "http values object is nil" }}
{{- end }}
{{- if not .url }}
  {{- fail "please specify the url parameter" }}
{{- end }}
{{- /**************************/ -}}
{{- if or .warmupNumRequests .warmupDuration }}
{{- $vals := mustDeepCopy . }}
{{- if .warmupNumRequests }}
{{- $_ := set $vals "numRequests" .warmupNumRequests }}
{{- else }}
{{- $_ := set $vals "duration" .warmupDuration}}
{{- end }}
{{- /* replace warmup options a boolean */ -}}
{{- $_ := unset $vals "warmupDuration" }}
{{- $_ := unset $vals "warmupNumRequests" }}
{{- $_ := set $vals "warmup" true }}
{{- if $vals.payloadURL }}
# task: download payload from payload URL
- run: |
    curl -o payload.dat {{ $vals.payloadURL }}
{{- $pf := dict "payloadFile" "payload.dat" }}
{{- $vals = mustMerge $pf $vals }}
{{- end }}
{{/* Write the warmup task */}}
# task: generate warmup HTTP requests
# collect Iter8's built-in HTTP latency and error-related metrics
- task: http
  with:
{{ toYaml $vals | indent 4 }}
{{- end }}
{{- /* warmup done */ -}}
{{- /**************************/ -}}
{{- /* Perform the various setup steps before the main task */ -}}
{{- /* remove warmup options if present */ -}}
{{- $_ := unset . "warmupDuration" }}
{{- $_ := unset . "warmupNumRequests" }}
{{- $vals := mustDeepCopy . }}
{{- if $vals.payloadURL }}
# task: download payload from payload URL
- run: |
    curl -o payload.dat {{ $vals.payloadURL }}
{{- $pf := dict "payloadFile" "payload.dat" }}
{{- $vals = mustMerge $pf $vals }}
{{- end }}
{{/* Write the main task */}}
# task: generate HTTP requests for app
# collect Iter8's built-in HTTP latency and error-related metrics
- task: http
  with:
{{ toYaml $vals | indent 4 }}
{{- end }}