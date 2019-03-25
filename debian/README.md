# Debian

A Debian Pod useful for debugging.

### Manifests

[`debian.yaml`](./debian.yaml) _(Pod)_

### Deploy

```bash
kubectl -n default apply -f ./debian-pod.yaml
```

### Usage

```bash
kubectl -n default exec -it debian -- /bin/bash
```
