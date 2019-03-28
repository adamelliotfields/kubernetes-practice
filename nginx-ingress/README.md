# NGINX Ingress Controller

An NGINX pod that watches the `/ingresses` endpoint to satisfy requests for ingress.

This is the easiest Ingress Controller to use and has the best documentation, in my opinion.

### Prerequisites

  - The default Service type is `LoadBalancer`, so you must have a way to satisfy the request for a load balancer.
    - If deploying to a managed cluster, this will incur a charge.
    - If deploying to a Kubeadm provisioned cluster, use [MetalLB](https://github.com/danderson/metallb).

### Helm Values

  - [`nginx-ingress-values.yaml`](./nginx-ingress-values.yaml)

### Configuration

This example deploys a DaemonSet (a Pod on each node), a ServiceMonitor, and enables stats and
metrics.

See the default [values](https://github.com/helm/charts/blob/master/stable/nginx-ingress/values.yaml)
for additional settings.

### Deploy

It is recommended to deploy the Ingress Controller in the `kube-system` namespace.

```bash
helm install stable/nginx-ingress \
-f ./nginx-ingress-values.yaml \
--name=nginx-ingress \
--namespace=kube-system
```

### Monitoring

The Helm chart has an option to automatically deploy a ServiceMonitor intended to be used by the 
Prometheus Operator.

Optionally, Prometheus scrape annotations can be added under `controller.metrics.service.annotations`
if not using the Prometheus Operator.

Note that you need to create an Ingress resource to allow incoming traffic, and that you need
incoming traffic to generate metrics. Also, only traffic on a named host will count towards metrics.
