# MySQL Operator

A Kubernetes controller for managing MySQL clusters, including backup and restoration.

### Prerequisites

  1. This example uses the [hostpath](https://github.com/rimusz/hostpath-provisioner) StorageClass.
  2. You must clone the [repository](https://github.com/oracle/mysql-operator) manually.
  3. The backup example requires a S3-compatible object store (Minio in this case)
     - a bucket must already exist (named `mysqldump` in this case)
     - the `MINIO_REGION` environment variable must have been set when you deployed Minio (set to `minio` in this case)

### Manifests

  - [`mysql-agent-default-rbac.yaml`](./mysql-agent-default-rbac.yaml) _(ServiceAccount, RoleBinding)_
  - [`mysql-cluster.yaml`](./mysql-cluster.yaml) _(Cluster)_
  - [`mysql-router.yaml`](./mysql-router.yaml) _(Service, Deployment)_
  - [`wordpress-backup.yaml`](./wordpress-backup.yaml) _(Backup)_
  - [`wordpress-restore.yaml`](./wordpress-restore.yaml) _(Restore)_

### Deploy

```bash
# Install the chart
helm install ./mysql-operator/mysql-operator \
--name=mysql-operator \
--namespace=mysql-operator

# Add ServiceAccount and RoleBinding to the default namespace
kubectl -n default apply -f ./mysql-operator-rbac.yaml

# Deploy a 3-node cluster
kubectl -n default apply -f ./mysql-cluster.yaml
```

### Router

MySQL Router is used to connect to a cluster from an application, instead of connecting to a node
directly. If the leader goes down, the cluster will elect a new leader and the router will
connect you to it automatically.

```bash
kubectl -n default apply -f ./mysql-router.yaml
```

### Backup

**Create `credentialSecret`**

The Minio Helm Chart creates a Secret with the `accesskey` and `secretkey` keys; however, the Backup
resource expects the "K" to be upper-cased. Thus, we must create a new secret.

See the [docs](https://github.com/oracle/mysql-operator/blob/master/docs/user/backup.md) for a
scheduled backup example.

```bash
MINIO_ACCESS_KEY=$(kubectl -n default get secret minio -o jsonpath='{.data.accesskey}' | base64 -d)
MINIO_SECRET_KEY=$(kubectl -n default get secret minio -o jsonpath='{.data.secretkey}' | base64 -d)

kubectl -n default create secret generic minio-credentials \
--from-literal=accessKey=${MINIO_ACCESS_KEY} \
--from-literal=secretKey=${MINIO_SECRET_KEY}
```

**Deploy the Backup**

```bash
kubectl -n default apply -f ./wordpress-backup.yaml
```

### Restore

The `clusterRef` is the name of the cluster to apply the backup to, while the backupRef is the
`metadata.name` of the Backup to use.

```bash
kubectl -n default apply -f ./wordpress-restore.yaml
```
