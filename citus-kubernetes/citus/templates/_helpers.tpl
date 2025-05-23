{{/*
Expand the name of the chart.
*/}}
{{- define "citus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "citus.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "citus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "citus.labels" -}}
helm.sh/chart: {{ include "citus.chart" . }}
{{ include "citus.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "citus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "citus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Coordinator selector labels
*/}}
{{- define "citus.coordinatorSelectorLabels" -}}
app: {{ .Values.coordinator.name }}
{{- end }}

{{/*
Worker selector labels
*/}}
{{- define "citus.workerSelectorLabels" -}}
app: {{ .Values.workers.name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "citus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "citus.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}