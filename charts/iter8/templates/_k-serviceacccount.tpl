{{- define "k.serviceaccount" -}}
{{- if not .Values.serviceAccountName }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Release.Name }}-iter8-sa
{{- end }}
{{- end }}
