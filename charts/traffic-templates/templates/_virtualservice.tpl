{{- define "initial.virtualservice" }}
{{- $versions := include "resolve.modelVersions" . | mustFromJson }}
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
          number: {{ .Values.modelmeshServingPort }}
      headers:
        request:
          set:
            mm-vmodel-id: {{ (index $versions 0).name }}
{{- end }}
