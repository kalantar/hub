{{- define "routemap-mirror" }}
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
        name: {{ default (printf "%s-%d" $i) $.Values.modelName $v.name }}-weight-config
        namespace: {{ default "modelmesh-serving" $v.namespace }}
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
            - route:
              - destination:
                  host: {{ $.Values.modelmeshServingEndpoint }}
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
                headers:
                  request:
                    set:
                      mm-vmodel-id: "{{ default (printf "%s-0" .Values.modelName) (index .Values.modelVersions 0).name }}"
              mirror:
                host: {{ $.Values.modelmeshServingEndpoint }}
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
              headers:
                  request:
                    set:
                      mm-vmodel-id: "{{ default (printf "%s-1" $.Values.modelName) (index .Values.modelVersions 1).name }}"
immutable: true
{{- end }}
