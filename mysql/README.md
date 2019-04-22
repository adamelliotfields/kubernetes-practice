# MySQL

A 3-node MySQL InnoDB Cluster with MySQL Router.

### Prerequisites

  1. This example uses the [hostpath](https://github.com/rimusz/hostpath-provisioner) StorageClass.

### Manifests

  - [`mysql.yaml`](./mysql.yaml) _(Secret, Service, StatefulSet)_
  - [`mysql-router.yaml`](./mysql-router.yaml) _(Service, Deployment)_

### Deploy

The manifest deploys a Secret, headless Service, and StatefulSet.

The Secret contains the MySQL root password. The `stringData` field is used for convenience (will
automatically be converted to base64).

The Service is a headless Service (no ClusterIP). The MySQL and MySQLX ports are mapped, as well as
the XCom port which is only used for communication by cluster members (you won't use it directly).

The StatefulSet will provision 3 PVCs with 10Gi storage each using the `hostpath` StorageClass.

Deploying to the `mysql` namespace.

```bash
kubectl -n mysql apply -f ./mysql.yaml
```

### Configuration

The Oracle MySQL image includes the following configuration settings in `/etc/my.cnf`.

```ini
[mysqld]
skip-host-cache
skip-name-resolve
datadir = /var/lib/mysql
socket = /var/lib/mysql/mysql.sock
secure-file-priv = /var/lib/mysql-files
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
```

Additionally, the following flags are used to provide additional settings required for group
replication.

```bash
--server_id=$(expr $(echo $HOSTNAME | grep -o '[^-]*$') + 1)
--report-host=${HOSTNAME}.mysql
--binlog-checksum=NONE
--enforce-gtid-consistency=ON
--gtid-mode=ON
```

### InnoDB Cluster

Some manual steps are needed to prepare the cluster for group replication.

First, get the CIDR block used to assign IP addresses to Pods. If you passed `--pod-network-cidr` to
`kubeadm init`, use that.

Cilium applies an annotation to Nodes, so we can get the CIDR from that. Note the escape slashes.

```bash
kubectl get node -o jsonpath='{.items[].metadata.annotations.io\.cilium\.network\.ipv4-pod-cidr}'
```

Once each replica has finished intializing, enable the Group Replication plugin and whitelist the
Pod CIDR.

```bash
for i in {0..2}; do
  cat <<'  EOF' | kubectl -n mysql exec -i db-${i} -- mysql -uroot -proot
INSTALL PLUGIN group_replication SONAME 'group_replication.so';
SET @@GLOBAL.group_replication_ip_whitelist = '10.1.0.0/16';
  EOF
done
```

The default value for `group_replication_ip_whitelist` is `AUTOMATIC`. To make sure it was properly
set to our Pod CIDR block, you can run the query `SELECT @@group_replication_ip_whitelist;` on each
cluster member.

Now run `mysqlsh` on `db-0` and connect to it.

```bash
kubectl -n mysql exec -it db-0 -- mysqlsh --uri='root:root@db-0.mysql'
```

Initiate the cluster. The member you run `createCluster()` on will automatically be added to the
cluster and set as the primary (R/W).

```javascript
var cluster = dba.createCluster('mysql');

cluster.addInstance('root:root@db-1.mysql');
cluster.addInstance('root:root@db-2.mysql');
```

Check the status of the cluster.

```javascript
cluster.status();
```

You should see the following result.

```json
{
  "clusterName": "mysql",
  "groupInformationSourceMember": "db-0.mysql:3306",
  "defaultReplicaSet": {
    "name": "default",
    "primary": "db-0.mysql:3306",
    "ssl": "REQUIRED",
    "status": "OK",
    "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
    "topologyMode": "Single-Primary",
    "topology": {
      "db-0.mysql:3306": { "address": "db-0.mysql:3306", "mode": "R/W", "readReplicas": {}, "role": "HA", "status": "ONLINE" },
      "db-1.mysql:3306": { "address": "db-1.mysql:3306", "mode": "R/O", "readReplicas": {}, "role": "HA", "status": "ONLINE" },
      "db-2.mysql:3306": { "address": "db-2.mysql:3306", "mode": "R/O", "readReplicas": {}, "role": "HA", "status": "ONLINE" }
    }
  }
}
```

### MySQL Router

The MySQL Router allows you to connect to a cluster instead of an individual member. This is useful
because the leader could go down, and a new leader would be elected. MySQL Router will automatically
route traffic to the new leader.

MySQL Router also provides dedicated ports for read-write and read-only queries. You could configure
your application to take advantage of this, so the leader is only responsible for write requests,
and read requests are load-balanced to the secondary members.

```bash
kubectl -n mysql apply -f ./mysql-router.yaml
```

We can use the `mysqlsh` CLI in one of the server Pods to connect to the router. Note that you must
provide the port, otherwise the shell will use the default port of 33060.

```bash
kubectl -n mysql exec -it db-0 -- mysqlsh --uri='root:root@mysql-router:6446'
```

### Pod Ordinal Naming

Each Pod controlled by the StatefulSet will be given an ordinal name based on the name of the
StatefulSet, starting at 0.

In this example, the StatefulSet is named `db`, so the first Pod would be named `db-0`.

The PVC used by the Pod would be named `mysql-db-0`, because the PVC is named `mysql`.

Because the Service is a headless Service, the DNS address for the Pod would be
`db-0.mysql.mysql.svc.cluster.local`, because the Service is named `mysql` and it is in the
`mysql` namespace. Pods within the `mysql` namespace can use the shorter `db-0.mysql` notation to
communicate with each other.

The ordinal index is useful as we can use it generate the `server_id` for each member, as shown in
the command for the StatefulSet PodSpec.
