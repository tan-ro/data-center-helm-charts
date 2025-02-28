{{/*This file contains template snippets used by the other files in this directory.*/}}
{{/*Most of them were generated by the "helm chart create" tool, and then some others added.*/}}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "bitbucket.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bitbucket.fullname" -}}
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
{{- define "bitbucket.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The name of the service account to be used.
If the name is defined in the chart values, then use that,
else if we're creating a new service account then use the name of the Helm release,
else just use the "default" service account.
*/}}
{{- define "bitbucket.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- if .Values.serviceAccount.create -}}
{{- include "bitbucket.fullname" . -}}
{{- else -}}
default
{{- end -}}
{{- end -}}
{{- end }}

{{/*
The name of the ClusterRole that will be created.
If the name is defined in the chart values, then use that,
else use the name of the Helm release.
*/}}
{{- define "bitbucket.clusterRoleName" -}}
{{- if .Values.serviceAccount.clusterRole.name }}
{{- .Values.serviceAccount.clusterRole.name }}
{{- else }}
{{- include "bitbucket.fullname" . -}}
{{- end }}
{{- end }}

{{/*
The name of the ClusterRoleBinding that will be created.
If the name is defined in the chart values, then use that,
else use the name of the ClusterRole.
*/}}
{{- define "bitbucket.clusterRoleBindingName" -}}
{{- if .Values.serviceAccount.clusterRoleBinding.name }}
{{- .Values.serviceAccount.clusterRoleBinding.name }}
{{- else }}
{{- include "bitbucket.clusterRoleName" . -}}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bitbucket.labels" -}}
helm.sh/chart: {{ include "bitbucket.chart" . }}
{{ include "bitbucket.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ with .Values.additionalLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bitbucket.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bitbucket.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "bitbucket.baseUrl" -}}
{{ ternary "https" "http" .Values.ingress.https -}}
://
{{- .Values.ingress.host -}}
{{ with .Values.ingress.port }}:{{ . }}{{ end }}
{{- end }}

{{- define "bitbucket.ingressPort" -}}
{{ default (ternary "443" "80" .Values.ingress.https) .Values.ingress.port -}}
{{- end }}

{{/*
The command that should be run by the nfs-fixer init container to correct the permissions of the shared-home root directory.
*/}}
{{- define "sharedHome.permissionFix.command" -}}
{{- if .Values.volumes.sharedHome.nfsPermissionFixer.command }}
{{ .Values.volumes.sharedHome.nfsPermissionFixer.command }}
{{- else }}
{{- printf "(chgrp %s %s; chmod g+w %s)" .Values.bitbucket.securityContext.gid .Values.volumes.sharedHome.nfsPermissionFixer.mountPath .Values.volumes.sharedHome.nfsPermissionFixer.mountPath }}
{{- end }}
{{- end }}

{{/*
The command that should be run to start the fluentd service
*/}}
{{- define "fluentd.start.command" -}}
{{- if .Values.fluentd.command }}
{{ .Values.fluentd.command }}
{{- else }}
{{- print "exec fluentd -c /fluentd/etc/fluent.conf -v" }}
{{- end }}
{{- end }}

{{- define "bitbucket.image" -}}
{{- if .Values.image.registry -}}
{{ .Values.image.registry}}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- end }}

{{/*
Defining additional init containers here instead of in values.yaml to allow template overrides
*/}}
{{- define "bitbucket.additionalInitContainers" -}}
{{- with .Values.additionalInitContainers }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Defining additional containers here instead of in values.yaml to allow template overrides
*/}}
{{- define "bitbucket.additionalContainers" -}}
{{- with .Values.additionalContainers }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Defining additional volume mounts here instead of in values.yaml to allow template overrides
*/}}
{{- define "bitbucket.additionalVolumeMounts" -}}
{{- with .Values.bitbucket.additionalVolumeMounts }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Defining additional environment variables here instead of in values.yaml to allow template overrides
*/}}
{{- define "bitbucket.additionalEnvironmentVariables" -}}
{{- with .Values.bitbucket.additionalEnvironmentVariables }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
For each additional library declared, generate a volume mount that injects that library into the Bitbucket lib directory
*/}}
{{- define "bitbucket.additionalLibraries" -}}
{{- range .Values.bitbucket.additionalLibraries }}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/bitbucket/app/WEB-INF/lib/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
For each additional plugin declared, generate a volume mount that injects that library into the Bitbucket plugins directory
*/}}
{{- define "bitbucket.additionalBundledPlugins" -}}
{{- range .Values.bitbucket.additionalBundledPlugins }}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/bitbucket/app/WEB-INF/atlassian-bundled-plugins/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "bitbucket.volumes" -}}
{{ if not .Values.volumes.localHome.persistentVolumeClaim.create }}
{{ include "bitbucket.volumes.localHome" . }}
{{- end }}
{{ include "bitbucket.volumes.sharedHome" . }}
{{- with .Values.volumes.additional }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{- define "bitbucket.volumes.localHome" -}}
{{- if not .Values.volumes.localHome.persistentVolumeClaim.create }}
- name: local-home
{{ if .Values.volumes.localHome.customVolume }}
{{- toYaml .Values.volumes.localHome.customVolume | nindent 2 }}
{{ else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}

{{- define "bitbucket.volumes.sharedHome" -}}
- name: shared-home
{{- if .Values.volumes.sharedHome.persistentVolumeClaim.create }}
  persistentVolumeClaim:
    claimName: {{ include "bitbucket.fullname" . }}-shared-home
{{ else }}
{{ if .Values.volumes.sharedHome.customVolume }}
{{- toYaml .Values.volumes.sharedHome.customVolume | nindent 2 }}
{{ else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}

{{- define "bitbucket.volumeClaimTemplates" -}}
{{ if .Values.volumes.localHome.persistentVolumeClaim.create }}
volumeClaimTemplates:
- metadata:
    name: local-home
  spec:
    accessModes: [ "ReadWriteOnce" ]
    {{- if .Values.volumes.localHome.persistentVolumeClaim.storageClassName }}
    storageClassName: {{ .Values.volumes.localHome.persistentVolumeClaim.storageClassName | quote }}
    {{- end }}
    {{- with .Values.volumes.localHome.persistentVolumeClaim.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "bitbucket.databaseEnvVars" -}}
{{ with .Values.database.driver }}
- name: JDBC_DRIVER
  value: {{ . | quote }}
{{ end }}
{{ with .Values.database.url }}
- name: JDBC_URL
  value: {{ . | quote }}
{{ end }}
{{ with .Values.database.credentials.secretName }}
- name: JDBC_USER
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ $.Values.database.credentials.usernameSecretKey }}
- name: JDBC_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ $.Values.database.credentials.passwordSecretKey }}
{{ end }}
{{ end }}

{{- define "bitbucket.sysadminEnvVars" -}}
{{ with .Values.bitbucket.sysadminCredentials }}
{{ if .secretName }}
- name: SETUP_SYSADMIN_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .secretName }}
      key: {{ .usernameSecretKey }}
- name: SETUP_SYSADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .secretName }}
      key: {{ .passwordSecretKey }}
- name: SETUP_SYSADMIN_DISPLAYNAME
  valueFrom:
    secretKeyRef:
      name: {{ .secretName }}
      key: {{ .displayNameSecretKey }}
- name: SETUP_SYSADMIN_EMAILADDRESS
  valueFrom:
    secretKeyRef:
      name: {{ .secretName }}
      key: {{ .emailAddressSecretKey }}
{{ end }}
{{ end }}
{{ end }}

{{- define "bitbucket.clusteringEnvVars" -}}
{{ if .Values.bitbucket.clustering.enabled }}
- name: KUBERNETES_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: HAZELCAST_KUBERNETES_SERVICE_NAME
  value: {{ include "bitbucket.fullname" . | quote }}
- name: HAZELCAST_NETWORK_KUBERNETES
  value: "true"
- name: HAZELCAST_PORT
  value: {{ .Values.bitbucket.ports.hazelcast | quote }}
{{ end }}
{{ end }}

{{- define "bitbucket.elasticSearchEnvVars" -}}
{{ with .Values.bitbucket.elasticSearch.baseUrl }}
- name: ELASTICSEARCH_ENABLED
  value: "false"
- name: PLUGIN_SEARCH_ELASTICSEARCH_BASEURL
  value: {{ . | quote }}
{{ end }}
{{ if .Values.bitbucket.elasticSearch.credentials.secretName }}
- name: PLUGIN_SEARCH_ELASTICSEARCH_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.bitbucket.elasticSearch.credentials.secretName | quote }}
      key: {{ .Values.bitbucket.elasticSearch.credentials.usernameSecreyKey | quote }}
- name: PLUGIN_SEARCH_ELASTICSEARCH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.bitbucket.elasticSearch.credentials.secretName | quote }}
      key: {{ .Values.bitbucket.elasticSearch.credentials.passwordSecretKey | quote }}
{{ end }}
{{ end }}
