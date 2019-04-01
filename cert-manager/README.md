# Cert Manager

Automatically issues and renews TLS certificates. The successor to `kube-lego`.

### Prerequisites

  - You must have public DNS records pointing to your cluster's external IP.
    * This includes subdomains like `www`.

### Manifests

  - [`letsencrypt-staging-clusterissuer.yaml`](./letsencrypt-staging-clusterissuer.yaml)

### Deploy

The chart in the Helm stable repository tends to lag behind upstream, so I recommend the official
repository from Jetstack.

The default values are fine.

Deploying to `kube-system` in this example.

```bash
# Install the Cert Manager CRDs first
kubectl -n kube-system apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/00-crds.yaml

# Add the certmanager.k8s.io/disable-validation label to kube-system
kubectl label ns kube-system certmanager.k8s.io/disable-validation=true

# Add the Jetstack repository to Helm
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install
helm install jetstack/cert-manager \
--name cert-manager \
--namespace kube-system
```

### Issuers

Cert Manager has two types of issuer resources - Issuer and ClusterIssuer.

An Issuer issues certificates within a specific namespace; whereas a ClusterIssuer issues
certificates for the entire cluster.

This example uses a ClusterIssuer, as it is simpler. Note that this uses Let's Encrypt's staging
server, which is better for testing, as the rate limits are much higher.

```bash
kubectl -n kube-system apply -f ./letsencrypt-staging-clusterissuer.yaml
```

### Certificates, Orders, and Challenges

When a request for a Certificate is created, an Order resource is created to request a certificate
from the ACME server.

The Order will create a Challenge resource for each host listed in `spec.tls` in the Ingress.

Before the Challenge is successful, Cert Manager will generate a self-signed certificate.

Once a Challenge is successful, it will be deleted; however, the Order will persist.

When visiting your site, if the certificate issuer is "cert-manager", then the Challenge hasn't
completed. You can debug Challenges using `kubectl describe`. In my experience, the issues have been
related to DNS records - either missing (subdomains) or not propagated yet.

### Ingress Shim

This is a component of Cert Manager responsible for automatically provisioning certificates based on
annotations on Ingress resources.

The list of supported annotations is [here](https://github.com/jetstack/cert-manager/blob/master/docs/tasks/issuing-certificates/ingress-shim.rst#supported-annotations).

The only required annotation is `certmanager.k8s.io/issuer` or `certmanager.k8s.io/cluster-issuer`.

### Example Ingress

Deploy an NGINX deployment and service into the `nginx` namespace:

```bash
kubectl create ns nginx

kubectl -n nginx run nginx --generator=apps/v1 --image=nginx:alpine --labels=app=nginx --replicas=1 --restart=Always --port=80 --expose=true
```

Create an Ingress (change `example.com` to your domain):

```bash
cat <<EOF | kubectl -n nginx apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/from-to-www-redirect: "true"
    certmanager.k8s.io/cluster-issuer: letsencrypt-staging
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
    - www.example.com
    secretName: example-com
EOF
```

Note that when using the `from-to-www-redirect` annotation, you cannot also list the `www` subdomain
if you want to redirect from `www`.
