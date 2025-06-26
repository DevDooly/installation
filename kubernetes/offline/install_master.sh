#!/bin/bash

## set hostname
hostnamectl set-hostname rhel01

## mount iso (vmware)
# mount -t iso9660 /dev/sr0 /media

## set repo (vmware)
# cat <<EOT > /etc/yum.repos.d/rhel.repo
# [rhel-BaseOS]
# name=Red Hat Enterprise Linux $releasever - $basearch - BaseOS
# baseurl=file:///media/BaseOS/
# gpgcheck=0
# Enabled=1
# 
# [rhel-AppStream]
# name=Red Hat Enterprise Linux $releasever - $basearch - AppStream
# baseurl=file:///media/AppStream/
# gpgcheck=0
# Enabled=1
# EOT

## yum check
# yum update

## 필수 패키지 설치
dnf install -y iproute-tc vim net-tools bash-completion nfs-utils curl wget device-mapper-persistent-data lvm2

## 초기 설정
swapoff -a
sed -i.bak '/ swap /s/^/#/' /etc/fstab

echo "firewalld disable"
systemctl stop firewalld
systemctl disable firewalld

setenforece 0
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# netowkr 설정
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

# containerd
## 설치
## doc url : https://kubernetes.io/docs/setup/production-environment/container-runtimes/
## download url : https://github.com/containerd/containerd/releases/download/v2.1.2/containerd-2.1.2-linux-amd64.tar.gz

## 설치파일 /root/work 에 보관

cd /root/work/containerd
# wget https://github.com/containerd/containerd/releases/download/v2.1.2/containerd-2.1.2-linux-amd64.tar.gz
# curl -kLO https://github.com/containerd/containerd/releases/download/v2.1.2/containerd-2.1.2-linux-amd64.tar.gz

tar -C /usr/local -xzf containerd-2.1.2-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system

# containerd.service 파일 준비
wget https://raw.githubusercontent.com/containerd/containerd/refs/heads/main/containerd.service
cp containerd.service /usr/local/lib/systemd/system/containerd.service

## runc 준비
wget https://github.com/opencontainers/runc/releases/download/v1.3.0/runc.amd64
cp runc.amd64 /usr/local/sbin/runc
chmod +x /usr/local/sbin/runc

## containerd service 등록
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now containerd

## containerd 설정
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

## crictl
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.33.0/crictl-v1.33.0-linux-amd64.tar.gz
tar -C /usr/local/bin -xzf crictl-v1.33.0-linux-amd64.tar.gz

mkdir -p /etc/crictl
cat << EOF_CONF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF_CONF

crictl --version

# k8s
## 준비
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubeadm"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubelet"

cp kubeadm /usr/bin/
cp kubectl /usr/bin/
cp kubelet /usr/bin

chmod +x /usr/bin/kube*

## kubelet 설정
cat <<EOT > /etc/systemd/system/kubelet.service
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT

mkdir -p /etc/systemd/system/kubelet.service.d
cat <<EOT > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
[Service]
Environment=
