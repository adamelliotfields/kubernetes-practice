# Cilium

Cilium is a CNI plugin using BPF instead of IP Tables.

This example uses the ETCD node and certificates deployed when creating a Kubeadm cluster.

### Create `cilium-etcd-secrets`

The certificates and paths here are created by Kubeadm. They could be different if you set up
Kubernetes and ETCD a different way.

```bash
USER=adam

sudo kubectl create secret generic cilium-etcd-secrets \
-n kube-system \
--kubeconfig="/home/${USER}/.kube/config" \
--from-file=etcd-client-ca.crt=/etc/kubernetes/pki/etcd/ca.crt \
--from-file=etcd-client.key=/etc/kubernetes/pki/etcd/server.key \
--from-file=etcd-client.crt=/etc/kubernetes/pki/etcd/server.crt
```

### Download `cilium-external-etcd`

Make sure the manifest matches your Kubernetes version (1.14 shown here).

```bash
wget https://raw.githubusercontent.com/cilium/cilium/v1.5.1/examples/kubernetes/1.14/cilium-external-etcd.yaml
```

### Edit the ConfigMap in the manifest

Change `EDIT-ME-ETCD-ADDRESS` to your ETCD advertise address (the public IP of your master node if
using Kubeadm). Make sure the protocol is `https`.

Note that on EC2, you must use the private IP. See [Public IPv4 Addresses](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html#vpc-public-ipv4-addresses).

Uncomment the lines for `ca-file`, `key-file`, and `cert-file`.

```yaml
...
data:
  etcd-config: |-
    ---
    endpoints:
      - https://EDIT-ME-ETCD-ADDRESS:2379
    ca-file: '/var/lib/etcd-secrets/etcd-client-ca.crt'
    key-file: '/var/lib/etcd-secrets/etcd-client.key'
    cert-file: '/var/lib/etcd-secrets/etcd-client.crt'
...
```

### Edit the Deployment in the manifest

Add the toleration to the PodSpec so you can deploy the Cilium Operator on the Master node.

```yaml
...
spec:
  template:
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
...
```

### Deploy Cilium

```bash
kubectl -n kube-system apply -f ./cilium-external-etcd.yaml
```
