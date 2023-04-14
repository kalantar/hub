{{- define "initialize.routemap" }}
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
    - weight: {{ default 100 $v.weight }}
      resources:
      - gvrShort: cm
        name: {{ default (printf "wisdom-%d" $i) $v.name }}-weight-config
        namespace: {{ default "modelmesh-serving" $v.namespace }}
      - gvrShort: isvc
        name: {{ default (printf "wisdom-%d" $i) $v.name }}
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
            - route:
              # primary model
              - destination:
                  host: {{ $.Values.modelmeshServingEndpoint }}
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
                {{ `{{- if gt (index .Weights 1) 0 }}` }}
                weight: {{ `{{ index .Weights 0 }}` }}
                {{ `{{- end }}`}}
                headers: 
                  request:
                    set:
                      mm-vmodel-id: "{{ default "wisdom-0" (index .Values.modelVersions 0).name }}" 
              # other models
{{- range $i, $v := (rest .Values.modelVersions) }}
              {{ `{{- if gt (index .Weights ` }}{{ print (add1 $i) }}{{ `) 0 }}`}}
              - destination:
                  host: {{ $.Values.modelmeshServingEndpoint }}
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
                weight: {{ `{{ index .Weights `}}{{ print (add1 $i) }}{{` }}`}}
                headers:
                  request:
                    set:
                      mm-vmodel-id: "{{ default (printf "wisdom-%d" (add1 $i)) $v.name }}" 
              {{ `{{- end }}`}}     
{{- end }}
immutable: true
{{- end }}
