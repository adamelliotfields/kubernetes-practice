# Hostpath Provisioner

A dynamic persistent volume provisioner that uses the host file system on single-node clusters.

Great for emulating the behavior of a cloud provider dynamic provisioner.

### Prerequisites

  - Must be used on a single-node cluster.

### Deploy

The default Helm values are fine.

```bash
helm repo add rimusz https://charts.rimusz.net
helm repo update

helm install rimusz/hostpath-provisioner \
--name=hostpath-provisioner \
--namespace=kube-system
```

### Usage

Deploy a MongoDB headless Service and StatefulSet, using the `hostpath` Storage Class to dynamically
provision a persistent volume.

```bash
cat <<EOF | kubectl -n mongo apply -f -
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
spec:
  selector:
    app: mongo
  clusterIP: None
  ports:
  - port: 27017
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  replicas: 1
  serviceName: mongo
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:3.6.11
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongo
          mountPath: /data/db
  volumeClaimTemplates:
  - metadata:
      name: mongo
    spec:
      storageClassName: hostpath
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
EOF
```
