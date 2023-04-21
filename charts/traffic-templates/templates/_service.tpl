{{- define "external.service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ default "mm-external" .Values.serviceName }}
  namespace: {{ default "modelmesh-serving" .Values.serviceNamespace }}
spec:
  externalName: istio-ingressgateway.istio-system.svc.cluster.local
  sessionAffinity: None
  type: ExternalName
{{- end }}
