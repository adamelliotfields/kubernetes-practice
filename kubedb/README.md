# KubeDB

An Operator from AppsCode for installing and managing databases.

### Prerequisites

  - This example uses the [hostpath](https://github.com/rimusz/hostpath-provisioner) StorageClass.

### Install

First, download the `kubedb` binary from GitHub.

```bash
sudo wget -O /usr/local/bin/kubedb https://github.com/kubedb/cli/releases/download/0.11.0/kubedb-linux-amd64
sudo chmod +x /usr/local/bin/kubedb
```

Add the AppsCode Helm repo.

```bash
helm repo add appscode https://charts.appscode.com/stable
helm repo update
```

Install the KubeDB Operator and Catalog charts.

```bash
helm install appscode/kubedb --name=kubedb-operator --namespace=kube-system
helm install appscode/kubedb-catalog --name=kubedb-catalog --namespace=kube-system
```

### Deploy MySQL

First, get the versions of MySQL available. You can list all available resources with `kubedb api-resources`.

```bash
kubedb get myversion
```

`8.0.14` is the latest at this time, so we will install that. Note that we are using `kubedb` not `kubectl`.

```bash
kubectl create ns mysql

cat <<EOF | kubedb -n mysql create -f -
apiVersion: kubedb.com/v1alpha1
kind: MySQL
metadata:
  name: mysql
spec:
  version: '8.0.14'
  storage:
    storageClassName: hostpath
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
  terminationPolicy: WipeOut
EOF
```

KubeDB will create a StatefulSet with 1 replica (`mysql-0`), a Secret with the root
password (`mysql-auth`), and 2 Services (a headless `kubedb` service, and a ClusterIP `mysql`
service).

The `terminationPolicy` is set to `WipeOut` for this example (the default is `Pause`). Read more
[here](https://kubedb.com/docs/0.11.0/concepts/databases/mysql/#spec-terminationpolicy).

Once the Pod is ready, you can use it.

```bash
echo 'SELECT User, Host, plugin FROM mysql.user;' | kubectl -n mysql exec -i mysql-0 -- mysql \
-uroot \
-p$(kubectl -n mysql get secret mysql-auth -o=jsonpath='{.data.password}' | base64 -d)
```

You can delete the namespace to clean everything up.

```bash
kubectl delete ns mysql
```
