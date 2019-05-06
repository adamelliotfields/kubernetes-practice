# Datadog

Datadog is a SaaS monitoring product with exceptional support for Docker and Kubernetes, with a
generous free plan.

The Kubernetes agent performs metrics scraping and optional log transport.

### Prerequisites

  - Create a free account at Datadog.

### Helm Values

  - [`datadog-values.yaml`](./datadog-values.yaml)

### Deploy

First go to <https://app.datadoghq.com/account/settings#api> to get your API Key.

Now, create a Secret (deploying to `kube-system` namespace).

```bash
kubectl -n kube-system create secret generic datadog-secret --from-literal=api-key=your_api_key
```

The Helm values enable the Cluster agent in addition to the standard Node agents that run as a
DaemonSet. The Cluster Agent reduces load on the API server by acting as a middle-man between each
Node agent and the API server.

The Cluster agent requires a token used to authenticate each Node agent. The token must be an
alphabetic string, at least 32 characters long. You can generate one using the following command.

```bash
cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z' | head -c 32
```

You can now deploy the agents.

```bash
helm install stable/datadog \
-f ./datadog-values.yaml \
--name=datadog \
--namespace=kube-system
```

It will take a few minutes for your hosts to show up on Datadog, and don't be alarmed if you see
duplicates. After a while, Datadog will auto-correct itself.
