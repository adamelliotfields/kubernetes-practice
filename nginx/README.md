# NGINX

A basic NGINX Deployment, Service, and Ingress.

### Prerequisites
  - You must have an Ingress Controller already deployed in your cluster.
  - You must have a domain name pointed at your cluster.

### Manifests

  - [`nginx.yaml`](./nginx.yaml) _(Service, Deployment, Ingress)_

### Deploy

Change `example.com` in the manifest to your domain name.

```bash
kubectl create ns nginx

kubectl -n nginx apply -f ./nginx.yaml
```

### Monitoring

If exporting Prometheus metrics from the NGINX Ingress Controller (not to be confused with the NGINX
web application deployed here), the Ingress resource must have a host; otherwise, metrics will not
be generated.
