# Metrics Server

Metrics Server is the successor to Heapster for providing Pod and Node resource utilization. It
provides the data for the `kubectl top` command and the Vertical Pod Autoscaler resource.

> At this time, Metrics Server has not been integrated into the Kubernetes Dashboard. If you plan on
> using the dashboard, stick with Heapster for now.

### Helm Values

  - [`metrics-server-values.yaml`](./metrics-server-values.yaml)

### Deploy

```bash
helm install stable/metrics-server \
-f ./metrics-server-values.yaml \
--name=metrics-server \
--namespace=kube-system
```

### Usage

```bash
# Display pod metrics for the given namespace
kubectl -n default top pod

# Display node metrics
kubectl top node
```
