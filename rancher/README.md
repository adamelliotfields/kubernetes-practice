# Rancher

Rancher itself can be run inside of a Kubernetes cluster for high-availability.

Note that it's not recommended for Rancher to be running in the same cluster that it is managing.

### Prerequisites

  - You must create a DNS (CNAME in this example) record for Rancher (e.g., `rancher.example.com`).
  - You must have Cert Manager running in your cluster.
    * This example uses a ClusterIssuer pointing at Let's Encrypt's staging server.
  - You must have the NGINX Ingress Controller running in your cluster.

### Manifests

  - [`rancher.yaml`](./rancher.yaml) _(Service, Deployment, Ingress)_

### Deploy

The Rancher server will be deployed to the `rancher-system` namespace. The Rancher node and cluster
agents will deploy themselves to the `cattle-system` namespace.

When you delete a cluster using the Rancher UI, it deletes the `cattle-system` Namespace in that
cluster, so it's important for Rancher to have its own Namespace.

```bash
kubectl create ns rancher-system
```

Create the `rancher` ServiceAccount with a `cluster-admin` ClusterRoleBinding.

```bash
kubectl -n rancher-system create sa rancher
kubectl create clusterrolebinding rancher --clusterrole=cluster-admin --serviceaccount=rancher-system:rancher
```

The Rancher node and cluster agents will try to connect to the Rancher server over HTTPS. If they
don't recognize the certificate authority, they will error indefinitely.

Because Let's Encrypt's staging server uses certificates from an unknown authority, Rancher will
need the root certificate. You can get it [here](https://letsencrypt.org/docs/staging-environment).

```bash
wget https://letsencrypt.org/certs/fakelerootx1.pem
```

Now you can create a Secret that will be mounted to the Rancher container in the Deployment.

```bash
kubectl -n rancher-system create secret generic tls-ca --from-file=cacerts.pem=./fakelerootx1.pem
```

Before deploying, change `rancher.example.com` in the manifest to your domain.

```bash
kubectl -n rancher-system apply -f ./rancher.yaml
```
