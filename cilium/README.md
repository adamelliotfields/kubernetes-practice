# Cilium

Cilium is a CNI plugin using BPF instead of IP Tables.

This example uses the ETCD node and certificates deployed when creating a Kubeadm cluster.

### Create `cilium-etcd-secrets`

The certificates and paths here are created by Kubeadm. They could be different if you set up
Kubernetes and ETCD a different way.

```bash
USER=adam

sudo kubectl -n kube-system create secret generic cilium-etcd-secrets \
-n kube-system \
--kubeconfig="/home/${USER}/.kube/config" \
--from-file=/etc/kubernetes/pki/etcd/ca.crt \
--from-file=/etc/kubernetes/pki/etcd/server.key \
--from-file=/etc/kubernetes/pki/etcd/server.crt
```

### Download `cilium-external-etcd`

Make sure the manifest matches your Kubernetes version (1.14 shown here).

```bash
wget https://raw.githubusercontent.com/cilium/cilium/v1.5.0-rc2/examples/kubernetes/1.14/cilium-external-etcd.yaml
```

### Edit the ConfigMap in the manifest

Change `EDIT-ME-ETCD-ADDRESS` to your ETCD advertise address (the public IP of your Master node if
using Kubeadm). Make sure the protocol is `https`.

```yaml
...
data:
  etcd-config: |-
    ---
    endpoints:
      - https://EDIT-ME-ETCD-ADDRESS:2379
    ca-file: '/var/lib/etcd-secrets/ca.crt'
    key-file: '/var/lib/etcd-secrets/server.key'
    cert-file: '/var/lib/etcd-secrets/server.crt'
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
