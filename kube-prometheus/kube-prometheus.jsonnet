local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local pvc = k.core.v1.persistentVolumeClaim;

local kp = (import 'kube-prometheus/kube-prometheus.libsonnet') + {
  _config+:: {
    namespace: 'monitoring',

    // https://github.com/coreos/prometheus-operator/blob/master/contrib/kube-prometheus/examples/prometheus-pvc.jsonnet
    prometheus+:: {
      replicas: 1,
      prometheus+: {
        spec+: {
          retention: '1w',
          storage: {
            volumeClaimTemplate:
              pvc.new() +
              pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
              pvc.mixin.spec.resources.withRequests({ storage: '10Gi' }) +
              pvc.mixin.spec.withStorageClassName('hostpath'),
          },
        },
      },
    },

    alertmanager+:: {
      replicas: 1,
    },

    grafana+:: {
      config: {
        sections: {
          // http://docs.grafana.org/auth/overview
          auth: {
            disable_login_form: true,
            disable_signout_menu: true,
          },
          'auth.anonymous': {
            enabled: true,
            org_role: 'Admin',
          },
          'auth.basic': {
            enabled: false,
          },
        },
      },
    },

    // https://github.com/coreos/prometheus-operator/blob/master/contrib/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-managed-cluster.jsonnet
    local j = super.jobs,
    jobs: {
      [k]: j[k]
      for k in std.objectFields(j)
      if !std.setMember(k, ['KubeControllerManager', 'KubeScheduler'])
    },
  },

  local p = super.prometheus,
  prometheus: {
    [q]: p[q]
    for q in std.objectFields(p)
    if !std.setMember(q, ['serviceMonitorKubeControllerManager', 'serviceMonitorKubeScheduler'])
  },
};

// https://github.com/coreos/prometheus-operator/blob/master/contrib/kube-prometheus/example.jsonnet
{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
