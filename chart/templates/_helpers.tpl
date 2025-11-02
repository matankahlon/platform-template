{{- /*
==============================================================================
_helpers.tpl - Helper Functions for Helm Templates
This file defines shared functions that all templates use
No need to change here usually!
==============================================================================
*/}}

{{- /*
  dcs-app.name: Returns the Chart name
  - If there's nameOverride in values, uses it
  - Otherwise uses name from Chart.yaml
  - Truncates to 63 characters (Kubernetes limit)
*/}}
{{- define "dcs-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
  dcs-app.fullname: Returns the full Resource name
  - If there's fullnameOverride in values, uses it
  - Otherwise: <release-name>-<chart-name>
  - Example: "production-my-app" or "staging-backend-api"
  - Truncates to 63 characters (Kubernetes limit)
*/}}
{{- define "dcs-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "dcs-app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
