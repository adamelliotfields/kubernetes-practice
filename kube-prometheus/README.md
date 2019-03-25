# Kube Prometheus

Kube Prometheus deploys a full Kubernetes monitoring stack including the Prometheus Operator,
Prometheus, AlertManager, node-exporter, kube-state-metrics, and Grafana.

It also includes Prometheus scrape rules and custom Grafana dashboards.

### Prerequisites

  1. You must have a Go environment
     - `GOPATH` defined
     - `GOPATH/bin` added to your `PATH` 
  2. Be familiar with [Jsonnet](https://jsonnet.org)
  3. This example uses the [hostpath](https://github.com/rimusz/hostpath-provisioner) StorageClass

### Configuration

This example has the following configuration changes:
  - Scale down Prometheus and AlertManager to 1 replica
  - Set Prometheus metric retention to 15 days and store in a PersistentVolume
  - Disable authentication for Grafana (only to be used by `kubectl port-forward`)
  - Disable scrape jobs and service monitors for kube-scheduler and kube-controller-manager

### Compile

```bash
# Install jsonnet
go get github.com/google/go-jsonnet/jsonnet

# Install jsonnet-bundler
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb

# Install gojsontoyaml
go get github.com/brancz/gojsontoyaml

# Create jsonnetfile
jb init

# Download kube-prometheus
jb install github.com/coreos/prometheus-operator/contrib/kube-prometheus/jsonnet/kube-prometheus/@v0.29.0

# Create output folder
mkdir manifests

# Compile jsonnet to JSON and convert to YAML
jsonnet -J vendor -m manifests "${kube-prometheus.jsonnet}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml; rm -f {}' -- {}
```

### Deploy

```bash
kubectl -n monitoring apply -f ./manifests/.
```

### Usage

Because no Ingress has been created, all applications should be accessed via `kubectl port-forward`.

```bash
# Prometheus UI
kubectl -n monitoring port-forward svc/prometheus-k8s 9090

# Grafana
kubectl -n monitoring port-forward svc/grafana 3000
```
