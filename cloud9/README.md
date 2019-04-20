# AWS Cloud9 IDE

AWS Cloud9 (formerly c9.io) is a browser-based, cloud IDE. It's totally free; you just need to
provide a server that you have SSH and sudo access to, even if it's not hosted on AWS.

I recommend using Lightsail now that they've [cut their prices in half](https://aws.amazon.com/about-aws/whats-new/2018/08/amazon-lightsail-announces-50-percent-price-drop-and-two-new-instance-sizes).
You'll also be able to connect to other AWS services through [VPC Peering](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html).

You'll need at least the $20/mo plan, which gives you 2 cores, 4GB of memory, 80GB of storage, and
4TB of outbound data (same as DigitalOcean, Vultr, Linode).

### Installation

Start with a Lightsail instance running Ubuntu 18.04. You can upload your own public SSH key or use
the default key provided for you.

You can follow the [guide](../kubeadm/) to install Docker and Kubernetes. You just need to change
the Docker URLs to `https://download.docker.com/linux/ubuntu` (change `stretch` to `bionic`, too).

In addition, you'll need to set up a Node.js environment as well as ncurses.

```bash
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -

sudo apt-get install -y nodejs python python-pip build-essential libncurses5-dev
```

Finally, create the `.c9` folder to avoid any permissions issues.

```bash
USER='adam'

mkdir "/home/${USER}/.c9"
```

### Networking

Before setting up a Cloud9 environment, you need to open the necessary ports.

| Service                                | Range         |
|----------------------------------------|---------------|
| SSH                                    | 22            |
| HTTP                                   | 80            |
| HTTPS                                  | 443           |
| ETCD                                   | 2379-2380     |
| API Server                             | 6443          |
| Kubelet, Scheduler, Controller Manager | 10250-10252   |
| NodePorts, Ephemeral Ports             | 30000 - 61000 |

You can now go to <https://console.aws.amazon.com/cloud9> and create a new environment.

_Note: Unselect Docker from the installation list since you already have it installed._

### Port Forwarding

Cloud9 will generate a URL for services running on port 8080. You can use this to view your internal
services using `kubectl port-forward` (e.g., Kubernetes Dashboard).

Note that this only applies to HTTP services (not databases).
