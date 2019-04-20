# MetalLB

A Load Balancer for bare-metal Kubernetes clusters, or clusters that don't have access to a cloud
provider load balancer.

### Prerequisites

  - A [compatible CNI plugin](https://metallb.universe.tf/installation/network-addons) (Cilium isn't on the list but it works)
  - Kube Proxy must not be running in IPVS mode (it's not by default)

### Helm Values

The address pool name can be anything you want. It's used by the `metallb.universe.tf/address-pool`
annotation to request an IP from a specific address pool (useful if you have multiple address
pools).

Protocol is either `layer2` or `bgp`. To use BGP, you need a dedicated router (hardware or a
dedicated Linux box running a software router) that speaks BGP. Layer 2 only requires an array of IP
addresses in CIDR notation. If you only have a single IP address (single node cluster), or you have
multiple IP addresses on different subnets, use the `/32` suffix. This [calculator](https://www.ipaddressguide.com/cidr)
will help.

The IP address in this example is localhost, so you should change it to the public IP(s) of your
cluster (private IPs on EC2).

  - [`metallb-values.yaml`](./metallb-values.yaml)

### Deploy

```bash
helm install stable/metallb \
-f ./metallb-values.yaml \
--name=metallb \
--namespace=kube-system
```

### Traffic Policy

When creating a LoadBalancer Service, the default Traffic Policy is `Cluster`. This policy will
evenly distribute traffic to all Pods exposed by the Service, regardless of which node they are
deployed to. The downside is that Kube Proxy will SNAT the source IP of the incoming request. It can
also redirect a request to a different node, creating an additional hop.

Alternatively, the `Local` Traffic Policy will maintain the source IP of the request; however, it
will only send traffic to Pods on the same node that received the request. This means that the
Ingress Controller Pod must be running on the node with the external IP. You can ensure proper
Pod assignment by using `nodeSelector` / `nodeAffinity` or deploying the Ingress Controller as a
Daemonset.

You can read more about external traffic policies [here](https://www.asykim.com/blog/deep-dive-into-kubernetes-external-traffic-policies).

To use the `Local` policy with `nginx-ingress`, your Helm values should contain:

```yaml
controller:
  service:
    externalTrafficPolicy: Local
```
