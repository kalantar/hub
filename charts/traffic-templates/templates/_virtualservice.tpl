{{- define "initial.virtualservice" }}
{{- $versions := include "resolve.modelVersions" . | mustFromJson }}
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
        host: {{ .Values.modelmeshServingEndpoint }}
        port:
          number: {{ .Values.modelmeshServingPort }}
      headers:
        request:
          set:
            mm-vmodel-id: {{ (index $versions 0).name }}
{{- end }}
