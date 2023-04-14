{{- define "external.gateway" }}kind: Gateway
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: {{ default "mm-external-gateway" .Values.gatewayName }}
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - {{ default "mm-external" .Values.serviceName }}.{{ default "modelmesh-serving" .Values.serviceNamespace }}
    - {{ default "mm-external" .Values.serviceName }}.{{ default "modelmesh-serving" .Values.serviceNamespace }}.svc
    - {{ default "mm-external" .Values.serviceName }}.{{ default "modelmesh-serving" .Values.serviceNamespace }}.svc.cluster.local
{{- end }}