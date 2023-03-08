{{- define "task.http" -}}
{{- /* Validate values */ -}}
{{- if not . }}
{{- fail "http values object is nil" }}
{{- end }}
{{/* url must be defined or a url must be defined for each endpoint */}}
{{- if not .url }}
{{- if .endpoints }}
{{- range $endpointID, $endpoint := .endpoints }}
{{- if not $endpoint.url }}
{{- fail (print "endpoint \"" (print $endpointID "\" does not have a url parameter")) }}
{{- end }}
{{- end }}
{{- else }}
{{- fail "please set the url parameter or the endpoints parameter" }}
{{- end }}
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
{{- $_ := set $vals "payloadFile" "payload.dat" }}
{{- end }}
# handle endpoints
{{- range $endpointID, $endpoint := $vals.endpoints }}
{{- if $endpoint.payloadURL }}
{{- $payloadFile := print $endpointID "_payload.dat" }}
# task: download payload from payload URL for endpoint
- run: |
    curl -o {{ $payloadFile }} {{ $endpoint.payloadURL }}
{{- $_ := set $endpoint "payloadFile" $payloadFile }}
{{- end }}
{{- end }}
{{/* Write the main task */}}
# task: generate HTTP requests for app
# collect Iter8's built-in HTTP latency and error-related metrics
- task: http
  with:
{{ toYaml $vals | indent 4 }}
{{- end }}