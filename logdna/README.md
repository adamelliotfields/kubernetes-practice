# LogDNA

LogDNA is a cloud-hosted logging service with first-class support for Kubernetes, a free plan, and
affordable pricing for retention.

### Prerequisites

  - Create a free account at LogDNA.

### Manifests

  - [`logdna.yaml`](./logdna.yaml) _(DaemonSet)_

### Deploy

Before deploying the DaemonSet you must first create a Secret named `logdna-agent-key` containing
your LogDNA Ingestion Key.

You can find your key by navigating to Organization > API Keys.

```bash
kubectl -n kube-system create secret generic logdna-agent-key --from-literal=logdna-agent-key=your_ingestion_key
```

Inside `logdna.yaml`, change the environment variable `LOGDNA_TAGS` to any comma-separated list of
tags (e.g., the name of your cluster).

```bash
kubectl -n kube-system apply -f ./logdna.yaml
```
