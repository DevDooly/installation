#!/bin/bash

MASTER_HOSTNAME=rhel01

# set hostname
hostnamectl set-hostname $MASTER_HOSTNAME

## vmware

## set repo
cat <<EOT > /etc/yum.repos.d/rhel.repo
[rhel-BaseOS]
name=Red Hat Enterprise LInux $releasever - $basearch - BaseOS
baseurl=file:///media/BaseOS/
gpgcheck=0
Enabled=1

[rhel-AppStream]
name=Red Hat Enterprise Linux $releasever - $basearch - AppStream
baseurl=file:///media/AppStream/
gpgcheck=0
Enabled=1
EOT

yum update

## 필수 패키지
dnf install -y iproute-tc vim net-tools bash-completion nfs-utils curl wget device-mapper-persistent-data lvm2

## 초기설정

## https://kubernetes.io/docs/setup/production-environment/container-runtimes/

## swap 메모리
swapoff -a
sed -i.bak '/ swap /s/^/#/' /etc/fstab

## 방화벽
systemctl stop firewalld
systemctl eisable firewalld

## selinux
setenforce 0 
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

## 
modprobe br_netfilter
cat <<EOT > /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOT

cat <<EOT > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOT
sysctl --system

## containerd
wget https://github.com/containerd/containerd/releases/download/v2.1.3/containerd-2.1.3-linux-amd64.tar.gz

tar -C /usr/local -xzf containerd-2.1.3-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system

wget https://raw.githubusercontent.com/containerd/containerd/refs/heads/main/containerd.service
cp containerd.service /usr/local/lib/systemd/system/containerd.service

## runc
wget https://github.com/opencontainers/runc/releases/download/v1.3.0/runc.amd64
cp runc.amd64 /usr/local/sbin/runc
chmod +x /usr/local/sbin/runc

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now containerd

## set containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

## crictl
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.33.0/crictl-v1.33.0-linux-amd64.tar.gz
tar -C /usr/local/bin -zxf crictl-v1.33.0-linux-amd64.tar.gz

mkdir -p /etc/crictl
cat << EOF_CONF > /etc/crictl.yaml
runtime-endpoint: unix///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF_CONF

crictl --version

## kubernetes
## https://kubernetes.io/releases/download/

wget https://dl.k8s.io/v1.33.2/bin/linux/amd/kubeadm
wget https://dl.k8s.io/v1.33.2/bin/linux/amd/kubectl
wget https://dl.k8s.io/v1.33.2/bin/linux/amd/kubectlkubelet

cp kubeadm /usr/bin
cp kubectl /usr/bin
cp kubelet /usr/bin

chmod +x /usr/bin/kube*

cat <<EOT > /etc/systemd/system/kubelet.service
[Unit]
Description=kubelct: TheKubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/kubelet
Restart=alwyas
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT

mkdir -p /etc/systemd/system/kubelet.service.d
cat <<EOT > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
EnvironmentFile=-/etc/sysconfig/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_KUBEADM_ARGS \$KUBELET_EXTRA_ARGS
EOT

## ㅓㄹ치 확인
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now kubelet


