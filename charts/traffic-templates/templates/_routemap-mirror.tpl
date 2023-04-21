{{- define "routemap-mirror" }}
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
{{- range $i, $v := $versions }}
    - weight: {{ $v.weight }}
      resources:
      {{- if gt $i 0 }}
      - gvrShort: cm
        name: {{ $v.name }}-weight-config
        namespace: {{ $v.namespace }}
      {{- end }}
      - gvrShort: isvc
        name: {{ $v.name }}
        namespace: {{ $v.namespace }}
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
            - match:
              - headers:
                  mm-model:
                    exact: {{ .Values.modelName }}
              route:
              - destination:
                  host: {{ .Values.modelmeshServingService }}.{{ .Values.modelmeshServingNamespace }}.svc.cluster.local
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
                headers:
                  request:
                    set:
                      mm-vmodel-id: "{{ (index $versions 0).name }}"
              mirror:
                host: {{ .Values.modelmeshServingService }}.{{ .Values.modelmeshServingNamespace }}.svc.cluster.local
                  port:
                    number: {{ $.Values.modelmeshServingPort }}
              mirrorPercentage:
                value: {{ (index $versions 1).weight }}
              headers:
                  request:
                    set:
                      mm-vmodel-id: "{{ (index $versions 1).name }}"
immutable: true
{{- end }}
