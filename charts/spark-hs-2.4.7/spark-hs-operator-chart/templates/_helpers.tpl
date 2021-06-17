{{/*
Expand the name of the chart.
*/}}
{{- define "spark-hs-operator-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "spark-hs-operator-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "spark-hs-operator-chart.selectorLabels" -}}
hpe.com/component: {{ .Chart.Name }}
{{- end }}

{{/*
labels
usage:
{{ include "spark-hs-operator-chart.labels" (dict "componentName" "FOO" "context" $) -}}
*/}}
{{- define "spark-hs-operator-chart.labels" -}}
hpe.com/component: {{ .componentName }}
hpe.com/tenant: {{ .context.Values.tenantNameSpace }}
{{- range $label := .context.Values.labels }}
hpe.com/{{ $label.name }}: {{ $label.value }}
{{- end }}
{{- end }}


{{/*
    Node Affinity
*/}}
{{- define "spark-hs-operator-chart.nodeAffinity" -}}
preferredDuringSchedulingIgnoredDuringExecution: {{ include "spark-hs-operator-chart.nodeAffinity.preferred" . }}
requiredDuringSchedulingIgnoredDuringExecution: {{ include "spark-hs-operator-chart.nodeAffinity" . }}
{{- end }}

{{/*
Return a preferred nodeAffinity definition
*/}}
{{- define "spark-hs-operator-chart.nodeAffinity.preferred" -}}
- preference:
    matchExpressions:
        - key: {{ .Values.nodeAfinityConfigs.storageNode.key  | quote }}
          operator: {{ .Values.nodeAfinityConfigs.storageNode.operator  | quote }}
  weight: 50
{{- end }}


{{/*
Return a required nodeAffinity definition
*/}}
{{- define "spark-hs-operator-chart.nodeAffinity.required" -}}
nodeSelectorTerms:
- matchExpressions:
    - key: {{ .Values.nodeAfinityConfigs.maprNode.key | quote}}
      operator: {{ .Values.nodeAfinityConfigs.maprNode.operator  | quote }}
    - key: {{ .Values.nodeAfinityConfigs.exclusiveCluster.key  | quote }}
      operator: "In"
      values:
        - "none"
        - {{ .Values.tenantNameSpace | quote }}
{{- end -}}

{{/*
Return a preferred podAffinity definition
*/}}
{{- define "spark-hs-operator-chart.podAntiAffinity.preferred" -}}
- podAffinityTerm:
    labelSelector:
        matchExpressions:
            - key: {{ .Values.podAfinityConfigs.componentKey  | quote }}
              operator: "In"
              values:
                - {{ .Chart.Name | quote }}
    topologyKey: {{ .Values.podAfinityConfigs.topologyKey | quote}}
  weight: 1
{{- end }}

{{/*
Return a liveness probe
*/}}
{{- define "spark-hs-operator-chart.probe.liveness" -}}
exec:
    command:
        - {{ .Values.livenessProbe.path }}
initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
successThreshold: {{ .Values.livenessProbe.successThreshold }}
timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
{{- end }}

{{/*
Return a readiness probe
*/}}
{{- define "spark-hs-operator-chart.probe.readiness" -}}
exec:
    command:
        - {{ .Values.readinessProbe.path }}
failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
successThreshold: {{ .Values.readinessProbe.successThreshold }}
timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
{{- end }}


{{/*
Return a lifecycle
*/}}
{{- define "spark-hs-operator-chart.probe.lifecycle" -}}
preStop:
    exec:
        command:
            - "sh"
            - {{ .Values.lifecycle.preStop.path }}
{{- end }}

{{/*
Return HttpPortSparkHsUI
*/}}
{{- define "spark-hs-operator-chart.getHttpPortSparkHsUI" -}}
{{- $httpPortSparkHsUI := .Values.ports.httpPort -}}
{{- if(not .Values.tenantIsUnsecure)  -}}
{{- $httpPortSparkHsUI = .Values.ports.httpsPort -}}
{{- end -}}
{{ print $httpPortSparkHsUI }}
{{- end -}}


{{/*
Return ports
*/}}
{{- define "spark-hs-operator-chart.ports" -}}
- name: "http"
  protocol: "TCP"
  containerPort: {{ include "spark-hs-operator-chart.getHttpPortSparkHsUI" . }}
- name: "ssh"
  protocol: "TCP"
  hostPort: {{ .Values.ports.sshHostPort }}
  containerPort: {{ .Values.ports.sshPort }}
{{- end }}


{{/*
Return SecurityContext
*/}}
{{- define "spark-hs-operator-chart.securityContext" -}}
capabilities:
    add:
     - SYS_NICE
     - SYS_RESOURCE
runAsGroup: {{ .Values.security.maprGid }}
runAsUser: {{ .Values.security.maprUid }}
{{- end }}

{{/*
Return Tolerations
*/}}
{{- define "spark-hs-operator-chart.tolerations" -}}
- key: hpe.com/compute-{{ .Values.tenantNameSpace }}
  operator: Exists
- key: hpe.com/{{ .Chart.Name }}-{{ .Values.tenantNameSpace }}
  operator: Exists
{{- end }}
