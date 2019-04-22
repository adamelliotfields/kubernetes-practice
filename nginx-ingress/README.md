# NGINX Ingress Controller

A Controller that watches the `/ingresses` endpoint to satisfy requests for ingress.

Behind the scenes, an NGINX container is dynamically configured using a ConfigMap, as well as
annotations on individual Ingress resources.

This is the easiest Ingress Controller to use and has the best documentation, in my opinion.

### Prerequisites

  - The default Service type is `LoadBalancer`, so you must have a way to satisfy the request for a load balancer.
    - If deploying to a managed cluster, this will incur a charge.
    - If deploying to a Kubeadm provisioned cluster, use [MetalLB](https://github.com/danderson/metallb).

### Helm Values

  - [`nginx-ingress-values.yaml`](./nginx-ingress-values.yaml)

This example applies a few configuration changes and enables monitoring using a ServiceMonitor. In
order to deploy a ServiceMonitor, you must have the Prometheus Operator in your cluster.

The external traffic policy is set to `Local`. This preserves the source IP address, at the cost of
potentially imbalanced load balancing. Read more about external traffic policies [here](https://www.asykim.com/blog/deep-dive-into-kubernetes-external-traffic-policies).

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

Optionally, Prometheus scrape annotations can be added under
`controller.metrics.service.annotations` if not using the Prometheus Operator.

Note that you need to create an Ingress resource to allow incoming traffic, and that you need
incoming traffic to generate metrics. Also, only traffic on a named host will count towards metrics.

### Security

The NGINX container deployed by the Ingress Controller includes [ModSecurity](https://modsecurity.org),
but it is disabled by default.

Additionally, the [OWASP ModSecurity Core Rule Set](https://modsecurity.org/crs) is also included,
but must be enabled.

```yaml
controller:
  config:
    enable-modsecurity: 'true'
    enable-owasp-modsecurity-crs: 'true'
```
