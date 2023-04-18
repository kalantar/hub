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
            - {{ default "mm-external-gateway" .Values.gatewayName }}
            hosts:
            - {{ default "mm-external" .Values.serviceName }}.{{ default "modelmesh-serving" .Values.serviceNamespace }}
            - {{ default "mm-external" .Values.serviceName }}.{{ default "modelmesh-serving" .Values.serviceNamespace }}.svc
            - {{ default "mm-external" .Values.serviceName }}.{{ default "modelmesh-serving" .Values.serviceNamespace }}.svc.cluster.local
            http:
            {{- range $i, $v := (rest $versions) }}
            {{ `{{- if gt (index .Weights ` }}{{ print (add1 $i) }}{{ `) 0 }}`}}
            - match:
{{ toYaml $v.match | indent 16 }}
              route:
              - destination:
                  host: {{ $.Values.modelmeshServingEndpoint }}
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
                  host: {{ $.Values.modelmeshServingEndpoint }}
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
                headers:
                  request:
                    set:
                      mm-vmodel-id: "{{ (index $versions 0).name }}"
immutable: true
{{- end }}
