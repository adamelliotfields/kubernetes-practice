# Kubeadm

> Provisioning instructions for a fresh Debian server using Kubeadm.

Your Master node should be 2CPU/2GB minimum. You can get around the 2-core minimum using the
`--ignore-preflight-errors` flag when running `kubeadm init`.

Worker nodes can be 1CPU/1GB, which are fine for web apps, but heavier workloads like databases will
require more memory.

All commands below are to be run by root.

### Preparation

First replace the stock `sshd_config` with a more secure one. You can view mine [here](https://gist.github.com/adamelliotfields/c12a78019cb964dcccf302263054f0b3).

You can optionally install [sshguard](https://bitbucket.org/sshguard/sshguard) to block brute-force
SSH attempts.

```bash
wget -O /etc/ssh/sshd_config https://gist.githubusercontent.com/adamelliotfields/c12a78019cb964dcccf302263054f0b3/raw/76ae941a41590033067c100bbf8591ce422fe879/sshd_config

service sshd restart
```

Create a new sudo user and copy the `.ssh` folder.

```bash
USER=adam

adduser --disabled-password --gecos '' "$USER"

usermod -aG sudo "$USER"

echo "$USER ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/$USER"

cp -r /root/.ssh "/home/${USER}"

chown -R "$USER":"$USER" "/home/${USER}/.ssh"
```

### Docker

```bash
apt-get update

apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

echo 'deb [arch=amd64] https://download.docker.com/linux/debian stretch stable' | tee /etc/apt/sources.list.d/docker-ce.list

apt-get update

# Get the latest 18.09 release
DOCKER_VERSION=$(apt-cache madison docker-ce | grep 18.09 | head -1 | awk -F ' \| ' '{print $2}')

apt-get install -y docker-ce="$DOCKER_VERSION" docker-ce-cli="$DOCKER_VERSION"

apt-mark hold docker-ce docker-ce-cli

groupadd docker

USER=adam

usermod -aG docker "$USER"

# Update the daemon arguments
sed -i 's/^ExecStart.*/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ --containerd=\/run\/containerd\/containerd.sock --exec-opt=native.cgroupdriver=systemd --iptables=false/g' /lib/systemd/system/docker.service

systemctl daemon-reload

systemctl enable docker.service

service docker restart

iptables -P FORWARD ACCEPT
```

### Kubernetes

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo 'deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

# Get the latest 1.14 release
KUBE_VERSION=$(apt-cache madison kubeadm | grep 1.14 | head -1 | awk -F ' \| ' '{print $2}')

apt-get install -y kubeadm="$KUBE_VERSION" kubectl="$KUBE_VERSION" kubelet="$KUBE_VERSION"

apt-mark hold kubeadm kubectl kubelet
```
