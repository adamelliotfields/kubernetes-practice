# NGINX

A basic NGINX Deployment, Service, and Ingress.

### Prerequisites
  - You must have an Ingress Controller already deployed in your cluster.

### Manifests

  - [`nginx.yaml`](./nginx.yaml) _(Service, Deployment, Ingress)_

### Deploy

```bash
kubectl -n default apply -f ./nginx.yaml
```

### Monitoring

If exporting Prometheus metrics from the NGINX Ingress Controller (not to be confused with the NGINX
web application deployed here), the Ingress resource must have a host; otherwise, metrics will not
be generated.

```yaml
spec:
  rules:
  - host: example.com
    http:
      paths:
      - backend:
          serviceName: nginx
          servicePort: 80
```

### Cert Manager

TODO
