# Kubeadm

> Provisioning instructions for a fresh Debian server using Kubeadm on DigitalOcean.

Your Master node should be 2CPU/2GB minimum. You can get around the 2-core minimum using the
`--ignore-preflight-errors` flag when running `kubeadm init`.

Worker nodes can be 1CPU/1GB, which are fine for web apps, but heavier workloads like databases will
require more memory.

Make sure you configure a [firewall](https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports)!

All commands below are to be run by root. You can also paste the contents of [cloud-init.sh](./cloud-init.sh)
into the User Data field of your cloud provider.

### Preparation

First replace the stock `sshd_config` with a more secure one. You can view mine [here](https://gist.github.com/adamelliotfields/c12a78019cb964dcccf302263054f0b3).

Note that this disables password authentication. Your server needs to have a RSA public key on it,
and you need to have the matching private key on any devices you plan on using to connect to the
server.

Optionally, you can install [sshguard](https://bitbucket.org/sshguard/sshguard) to block brute-force
SSH attempts.

```bash
SSHD_CONFIG_URL='https://gist.githubusercontent.com/adamelliotfields/c12a78019cb964dcccf302263054f0b3/raw/0275c07893bef7d41945be7f5dcd62c7451da0c5/sshd_config'

wget -q -O /etc/ssh/sshd_config "$SSHD_CONFIG_URL"

service sshd restart
```

Create a new sudo user and copy the `.ssh` folder. This process could be different depending on how
your cloud provider provisions VMs for you. Basically, you want a passwordless sudo user with a
public RSA key in `~/.ssh/authorized_keys`.

```bash
USER='adam'

adduser --disabled-password --gecos '' "$USER"

usermod -aG sudo "$USER"

echo "$USER ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/${USER}"

cp -r /root/.ssh "/home/${USER}"

chown -R "$USER":"$USER" "/home/${USER}/.ssh"
```

### Micro

The Micro text editor is useful for editing files and `kubectl edit`.

```bash
MICRO_VERSION='1.4.1'

wget -q -O "/tmp/micro-${MICRO_VERSION}-linux64.tar.gz" "https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64.tar.gz"

tar -C /tmp -xzf "/tmp/micro-${MICRO_VERSION}-linux64.tar.gz"

cp "/tmp/micro-${MICRO_VERSION}/micro" /usr/local/bin/micro

chmod +x /usr/local/bin/micro

cat <<'EOF' | tee /etc/profile.d/micro.sh > /dev/null
export EDITOR='/usr/local/bin/micro'
export VISUAL="$EDITOR"
EOF
```

### Docker

Kubeadm 1.14 will throw a preflight error if Docker is using the default `cgroupfs` driver, so the
`--exec-opt` flag is used to change it to `systemd`.

Docker also sets the IPTables `FORWARD` policy to `DROP`, so the `--iptables` flag is set to
`false`, and the policy is set back to `ACCEPT` afterwards.

```bash
USER='adam'

# Get the latest 18.09 release
# apt-cache madison docker-ce | grep 18.09 | head -1 | awk -F \| '{print $2}' | sed 's/\s//g'
DOCKER_VERSION='5:18.09.4~3-0~debian-stretch'

apt-get update

apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

echo 'deb [arch=amd64] https://download.docker.com/linux/debian stretch stable' | tee /etc/apt/sources.list.d/docker-ce.list

apt-get update

apt-get install -y docker-ce="$DOCKER_VERSION" docker-ce-cli="$DOCKER_VERSION"

apt-mark hold docker-ce docker-ce-cli

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
# Get the latest 1.14 release
# apt-cache madison kubeadm | grep 1.14 | head -1 | cut -d '|' -f 2 | xargs
KUBE_VERSION='1.14.0-00'

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo 'deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y kubeadm="$KUBE_VERSION" kubectl="$KUBE_VERSION" kubelet="$KUBE_VERSION"

apt-mark hold kubeadm kubectl kubelet

systemctl enable kubelet.service
```

You can now run `kubeadm init` on your Master node. Once it's finished, copy your `KUBECONFIG` to
your home folder (or use SCP to copy to your local device).

```bash
USER='adam'

mkdir -p "/home/${USER}/.kube"

cp /etc/kubernetes/admin.conf "/home/${USER}/.kube/config"

chown -R "$USER":"$USER" "/home/${USER}/.kube"
```

You can now install a CNI plugin (Weave, Flannel, Cilium, etc) and add Worker nodes to your cluster.

If you need to schedule workloads on the Master node, run

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

to remove the default `NoSchedule` taint.
