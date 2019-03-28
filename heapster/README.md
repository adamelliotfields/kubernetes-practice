# Heapster

Provides an API for cluster resource utilization metrics. Primarily used by the Kubernetes Dashboard
and `kubectl top` command.

### Helm Values

  - [`heapster-values.yaml`](./heapster-values.yaml)

### Deploy

You need to first create a ServiceAccount and ClusterRoleBinding for Heapster to use.

```bash
kubectl -n kube-system create sa heapster

kubectl create clusterrolebinding heapster \
--clusterrole=cluster-admin \
--serviceaccount=kube-system:heapster
```

The Helm values instruct Heapster to use the insecure Kubelet port, and use the ServiceAccount we
just created.

```bash
helm install stable/heapster \
-f ./heapster-values.yaml \
--name=heapster \
--namespace=kube-system
```
