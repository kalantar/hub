{{- define "external.service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ default "mm-external" .Values.serviceName }}
spec:
  externalName: istio-ingressgateway.istio-system.svc.cluster.local
  sessionAffinity: None
  type: ExternalName
{{- end }}
