# Argo Tunnel

An Ingress controller from Cloudflare that connects your Service directly to Cloudflare's
datacenters without exposing any external ports.

### Prerequisites

  - You must have a domain pointing to Cloudflare's nameservers.
  - You must purchase Argo Tunnel through your Cloudflare account.

### Helm Values

  - [`argo-tunnel-values.yaml`](./argo-tunnel-values.yaml)

### Cloudflared

Cloudflared is the command line client for Argo Tunnel. It can be installed using Homebrew or
downloaded [here](https://developers.cloudflare.com/argo-tunnel/downloads).

Log into Cloudflare in your browser and then run `cloudflared login`. It will launch your browser
and ask you which domain to use Argo Tunnel with.

A certificate will then be copied to `~/.cloudflared/cert.pem`. You'll need this to create a Secret.

### Deploy

Add the Cloudflare Helm repository.

```bash
helm repo add cloudflare https://cloudflare.github.io/helm-charts
```

The default values are fine, but know that setting multiple replicas will require a Cloudflare load
balancer, which incurs an additional monthly charge.

Deploying to `kube-system`.

```bash
helm install cloudflare/argo-tunnel \
-f ./argo-tunnel-values.yaml \
--name=argo-tunnel \
--namespace=kube-system
```

### Example Ingress

Create a secret using the `cert.pem` provided by Cloudflared in the `nginx` namespace.

```bash
kubectl create ns nginx

kubectl -n nginx create secret generic example-com --from-file="$HOME/.cloudflared/cert.pem"
```

Deploy an NGINX deployment and service.

```bash
cat <<EOF | kubectl -n nginx apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
EOF

cat <<EOF | kubectl -n nginx apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.16.0-alpine
        ports:
        - containerPort: 80
EOF
```

Create an Ingress (change `example.com` to your domain):

```bash
cat <<EOF | kubectl -n nginx apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx
  labels:
    app: nginx
  annotations:
    kubernetes.io/ingress.class: argo-tunnel
spec:
  rules:
  - host: example.com
    http:
      paths:
      - backend:
          serviceName: nginx
          servicePort: 80
  tls:
  - hosts:
    - example.com
    secretName: example-com
EOF
```

Cloudflare will automatically create a CNAME record for your domain.
