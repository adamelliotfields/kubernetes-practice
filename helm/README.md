# Helm

The Kubernetes package manager.

### Install

First download the Helm binary.

```bash
wget -P /tmp https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz
tar -C /tmp -xzf /tmp/helm-v2.13.1-linux-amd64.tar.gz
sudo cp /tmp/linux-amd64/helm /user/local/bin/helm
```

Before deploying Tiller to the cluster, you need to create a ServiceAccount and ClusterRoleBinding.

```bash
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
```

Now you can deploy Tiller. By default, Tiller will be deployed to the `kube-system` namespace.

```bash
helm init --service-account=tiller
```

You can also use the `--node-selectors` flag to deploy Tiller to a node with specific label.

```bash
helm init --service-account=tiller --node-selectors='kubernetes.io/hostname=your_host_name'
```
