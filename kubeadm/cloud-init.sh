#!/bin/bash

set -euo pipefail

USER='adam'
MICRO_VERSION='1.4.1'
DOCKER_VERSION='5:18.09.4~3-0~debian-stretch'
KUBE_VERSION='1.14.0-00'
SSHD_CONFIG_URL='https://gist.githubusercontent.com/adamelliotfields/c12a78019cb964dcccf302263054f0b3/raw/0275c07893bef7d41945be7f5dcd62c7451da0c5/sshd_config'

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg2 gzip htop software-properties-common tar wget

wget -q -O /etc/ssh/sshd_config "$SSHD_CONFIG_URL"
wget -q -O "/tmp/micro-${MICRO_VERSION}-linux64.tar.gz" "https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64.tar.gz"

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo 'deb [arch=amd64] https://download.docker.com/linux/debian stretch stable' | tee /etc/apt/sources.list.d/docker-ce.list > /dev/null
echo 'deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y docker-ce="$DOCKER_VERSION" docker-ce-cli="$DOCKER_VERSION" kubeadm="$KUBE_VERSION" kubectl="$KUBE_VERSION" kubelet="$KUBE_VERSION"
apt-mark hold docker-ce docker-ce-cli kubeadm kubectl kubelet

tar -C /tmp -xzf "/tmp/micro-${MICRO_VERSION}-linux64.tar.gz"
cp "/tmp/micro-${MICRO_VERSION}/micro" /usr/local/bin/micro
chmod +x /usr/local/bin/micro

cat <<'EOF' | tee /etc/profile.d/micro.sh > /dev/null
export EDITOR='/usr/local/bin/micro'
export VISUAL="$EDITOR"
EOF

adduser --disabled-password --gecos '' "$USER"

cp -r /root/.ssh "/home/${USER}"
chown -R "$USER":"$USER" "/home/${USER}/.ssh"

usermod -aG sudo "$USER"
usermod -aG docker "$USER"

echo "$USER ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/${USER}" > /dev/null

sed -i 's/^ExecStart.*/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ --containerd=\/run\/containerd\/containerd.sock --exec-opt=native.cgroupdriver=systemd --iptables=false/g' /lib/systemd/system/docker.service

systemctl daemon-reload
systemctl enable docker.service
systemctl enable kubelet.service

service docker restart
service sshd restart

iptables -P FORWARD ACCEPT
