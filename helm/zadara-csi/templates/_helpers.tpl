{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "helm.labels" -}}
app.kubernetes.io/name: {{ include "helm.name" . }}
helm.sh/chart: {{ include "helm.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ include "helm.name" . }}
version: {{ .Chart.AppVersion }}
release: {{ .Release.Name }}
{{- range $key, $val := .Values.labels }}
{{ $key }}: {{ $val | quote }}
{{- end }}
publisher: "zadara"
provisioner: {{ .Values.plugin.provisioner }}
{{- end -}}

{{/*
Common selector labels
*/}}
{{- define "helm.selector.labels" -}}
app.kubernetes.io/name: {{ include "helm.name" . }}
helm.sh/chart: {{ include "helm.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ include "helm.name" . }}
version: {{ .Chart.AppVersion | quote  }}
release: {{ .Release.Name }}
{{- range $key, $val := .Values.labels }}
{{ $key }}: {{ $val | quote }}
{{- end }}
publisher: "zadara"
provisioner: {{ .Values.plugin.provisioner }}
{{- end -}}

{{/*
Choose snapshots API version based on installed CRDs.
If CRDs are not installed, then based on k8s version.
*/}}
{{- define "snapshots.autoVersion" -}}
{{- if .Capabilities.APIVersions.Has "snapshot.storage.k8s.io/v1/VolumeSnapshot" -}}
v1
{{- else if .Capabilities.APIVersions.Has "snapshot.storage.k8s.io/v1beta1/VolumeSnapshot" -}}
v1beta1
{{- else -}}
{{ ternary "v1" "v1beta1" (semverCompare ">=1.20.0" .Capabilities.KubeVersion.Version) }}
{{- end -}}
{{- end -}}

{{/*
Expected snapshots API version: either from user, or whatever "auto" resolves to.
*/}}
{{- define "snapshots.version" -}}
{{- if ne .Values.snapshots.apiVersion "auto" -}}
{{ .Values.snapshots.apiVersion }}
{{- else -}}
{{ include "snapshots.autoVersion" . }}
{{- end -}}
{{- end -}}
