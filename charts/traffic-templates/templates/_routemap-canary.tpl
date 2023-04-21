{{- define "routemap-canary" }}
{{- $versions := include "resolve.modelVersions" . | mustFromJson }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.modelName }}-routemap
  labels:
    app.kubernetes.io/managed-by: iter8
    iter8.tools/kind: routemap
    iter8.tools/version: {{ .Values.iter8Version }}
data:
  strSpec: |
    versions: 
    {{- range $i, $v := .Values.modelVersions }}
    - resources:
      - gvrShort: isvc
        name: {{ default (printf "%s-%d" $.Values.modelName $i) $v.name }}
        namespace: {{ default "modelmesh-serving" $v.namespace }}
    {{- end }}
    routingTemplates:
      {{ .Values.trafficStrategy }}:
        gvrShort: vs
        template: |
          apiVersion: networking.istio.io/v1beta1
          kind: VirtualService
          metadata:
            name: {{ .Values.modelName }}
          spec:
            gateways:
            - mesh
            hosts:
            - {{ .Values.modelmeshServingService }}.{{ .Values.modelmeshServingNamespace }}
            - {{ .Values.modelmeshServingService }}.{{ .Values.modelmeshServingNamespace }}.svc
            - {{ .Values.modelmeshServingService }}.{{ .Values.modelmeshServingNamespace }}.svc.cluster.local
            http:
            {{- range $i, $v := (rest $versions) }}
            {{ `{{- if gt (index .Weights ` }}{{ print (add1 $i) }}{{ `) 0 }}`}}
            - match:
                headers:
                  mm-model:
                    exact: {{ $.Values.modelName }}
              {{- if (hasKey $v.match "headers") }}
{{ toYaml (pick $v.match "headers").headers | indent 18 }}
              {{- end }}
              {{- if gt (omit $v.match "headers" | keys | len) 0 }}
{{ toYaml (omit $v.match "headers") | indent 16 }}
              {{- end }}
              route:
              - destination:
                  host: {{ $.Values.modelmeshServingService }}.{{ $.Values.modelmeshServingNamespace }}.svc.cluster.local
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
                headers:
                  request:
                    set:
                      mm-vmodel-id: "{{ (index $versions (add1 $i)).name }}"
            {{ `{{- end }}`}}
            {{- end }}
            - route:
              - destination:
                  host: {{ $.Values.modelmeshServingService }}.{{ $.Values.modelmeshServingNamespace }}.svc.cluster.local
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
                headers:
                  request:
                    set:
                      mm-vmodel-id: "{{ (index $versions 0).name }}"
immutable: true
{{- end }}
