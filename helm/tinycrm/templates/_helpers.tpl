{{- define "tinycrm.labels" -}}
app.kubernetes.io/name: tinycrm
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end }}
{{- define "tinycrm.selector" -}}
app.kubernetes.io/name: tinycrm
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
