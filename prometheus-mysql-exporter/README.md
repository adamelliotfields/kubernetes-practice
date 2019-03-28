# Prometheus MySQL Exporter

Prometheus exporter for MySQL Server metrics.

### Prerequisites

You must create a user for the exporter with necessary grants.

```sql
CREATE USER 'exporter'@'%' IDENTIFIED WITH mysql_native_password BY 'exporter' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* to 'exporter'@'%';
```

### Helm Values

  - [`prometheus-mysql-exporter-values.yaml`](./prometheus-mysql-exporter-values.yaml)

### Manifests

  - [`prometheus-mysql-exporter-servicemonitor.yaml`](./prometheus-mysql-exporter-servicemonitor.yaml)

### Configuration

The Helm values file includes the service of the host to scrape, as well as the password for the
`exporter` user.

The host in this example is the master node of the cluster deployed using the MySQL Operator.

See the default [values](https://github.com/helm/charts/blob/master/stable/prometheus-mysql-exporter/values.yaml)
for additional settings.

### Deploy

Deploy the exporter in the same namespace as the database you want to scrape.

```bash
helm install stable/prometheus-mysql-exporter \
-f ./prometheus-mysql-exporter-values.yaml \
--name=prometheus-mysql-exporter \
--namespace=default
```

### Prometheus Operator

The Prometheus Operator by default does not look for annotations like `prometheus.io/scrape`.
Instead, ServiceMonitors are to be deployed.

```bash
kubectl -n default apply -f ./prometheus-mysql-exporter-servicemonitor.yaml
```

To verify this worked, you should see _default/prometheus-mysql-exporter/0 (1/1 up)_ in the Targets
section of the Prometheus UI.

### Grafana Dashboard

Percona has provided a number of dashboards for MySQL in their [grafana-dashboards](https://github.com/percona/grafana-dashboards)
repository. Note that some panels will not work as they were intended to be used with Percona's
custom monitoring solution. Also note that the dashboards expect the data source to be "Prometheus",
so you may have to edit the file if your data souce is "prometheus" (lower case).

The MySQL Overview dashboard is a good starting point.
