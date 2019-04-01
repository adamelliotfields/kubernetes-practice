# Minio

A S3-compatible object storage server written in Go with a React UI. Can be run standalone or
distributed.

### Prerequisites

  - This example uses the [hostpath](https://github.com/rimusz/hostpath-provisioner) StorageClass.

### Helm Values

The chart defaults to 10Gi ReadWriteOnce for storage request.

Some S3 clients require a region, so you'll need to set this environment variable. The example uses
`us-east-1`, but you can set it to anything you want (it doesn't have to be a real S3 region).

  - [`minio-values.yaml`](./minio-values.yaml)

### Deploy

```bash
helm install stable/minio \
-f ./minio-values.yaml \
--name=minio \
--namespace=default
```

### Distributed

Running a distributed Minio cluster is simple via Helm, but note that the minimum number of replicas
is 4 (the default value). This will request 1 CPU core, 1GB of memory, and 4x 10GB storage volumes,
so keep that in mind if your cluster has limited resources and you're trying to keep monthly costs
down.

Add the following to your Helm values to enable distributed mode:

```yaml
mode: distributed
```
