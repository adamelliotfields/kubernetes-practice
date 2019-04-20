# Kubernetes Dashboard

The official UI for Kubernetes, written in Angular.

### Helm Values

  - [`kubernetes-dashboard-values.yaml`](./kubernetes-dashboard-values.yaml)

### Deploy

The Helm values enable the "skip login" button and use the `cluster-admin` role for RBAC. The
dashboard is served over HTTP on port 9090 instead of HTTPS on port 443.

This setup makes trying out the dashboard simple, but is literally the most insecure configuration.

```bash
helm install stable/kubernetes-dashboard \
-f ./kubernetes-dashboard-values.yaml \
--name=kubernetes-dashboard \
--namespace=kube-system
```

### Usage

The easiest way to access the dashboard is via port forwarding.

```bash
kubectl -n kube-system port-forward svc/kubernetes-dashboard 9090
```

### Heapster

In order to get the nice resource utilization charts, you must be running Heapster in your cluster.
Note that Heapster is deprecated though, and the team is working on integrating `metrics-server`
into the dashboard.
