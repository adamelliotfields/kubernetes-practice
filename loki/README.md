# Loki

A log aggregator from Grafana optimized for clusters already running Prometheus.

### Prerequisites

  - You must already have Grafana deployed in your cluster to actually view the log data.
  - This example uses the [hostpath](https://github.com/rimusz/hostpath-provisioner) StorageClass.

### Helm Values

  - [`loki-values.yaml`](./loki-values.yaml)

### Deploy

When enabling persistence, the chart defaults to 10Gi ReadWriteOnce for storage request.

Deploying to the monitoring namespace so it can be alongside Prometheus and Grafana.

```bash
# Clone the Loki repo first
git clone https://github.com/grafana/loki.git

helm install ./loki/production/helm \
-f /home/adam/charts/loki.yaml \
--name=loki \
--namespace=monitoring
```

### Usage

Log into Grafana and add the Loki datasource (in the configuration menu). The URL is
<http://loki.monitoring.svc.cluster.local:3100/>.

To query and view logs, click the Explore link in the menu.

The Helm chart deploys Loki's agent, Promtail, as a DaemonSet. By default, it will ingest logs from
`/var/log/pods`. Basically, if you can run `kubectl logs` against a Pod, it will be there. For
containers that do not output to `stdout`, you'll want to deploy Promtail as a sidecar container and
configure it to ingest the log file.

Alternatively, you can use [logcli](https://github.com/grafana/loki/blob/master/docs/logcli.md) to
query Loki from the command-line.
