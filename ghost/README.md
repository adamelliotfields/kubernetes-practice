# Ghost

A Node.js blogging application.

### Prerequisites

  - You must have a MySQL database already deployed.
  - You must have an Ingress Controller already deployed to your cluster.
  - This example uses the [hostpath](https://github.com/rimusz/hostpath-provisioner) StorageClass.

### Manifests

  - [`ghost.yaml`](./ghost.yaml) _(PVC, Service, Deployment, Ingress)_

### Configuration

Use a ConfigMap to store the Ghost configuration file. Ghost can also be configured using
environment variables or option flags, but this is the cleanest approach in my opinion.

Change the `url` to the host or IP address that you'll use to access Ghost. This setting is used by
Ghost to generate link URLs.

```bash
kubectl -n default create cm ghost-config --from-file=config.production.json
```

### Deploy

```bash
kubectl -n default apply -f ./ghost.yaml
```

### Database

This example connects Ghost to a MySQL Router service in front of a MySQL cluster. Because the
cluster uses Group Replication, every table must have a Primary Key. As of Ghost 2.18.3, two tables
will need to be updated for this to work.

After Ghost has finished the initial database seed, connect to MySQL and run the following:

```sql
ALTER TABLE ghost.brute MODIFY COLUMN `key` VARCHAR(191) NOT NULL PRIMARY KEY;
ALTER TABLE ghost.migrations_lock MODIFY COLUMN lock_key VARCHAR(191) NOT NULL PRIMARY KEY;
```

If you're connecting to a standalone MySQL database that is not part of a cluster, you don't need to
do this. Note that once you call `dba.createCluster()` from the MySQL shell, cluster rules apply,
regardless of the size of your cluster.
