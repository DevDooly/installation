#!/bin/bash
set -e

# 1. 필수 패키지 설치
dnf install -y conntrack ipvsadm ipset socat util-linux curl wget bash-completion

# 2. runc 설치
install -m 755 ./runc /usr/local/sbin/runc

# 3. containerd 설치 및 설정
mkdir -p /etc/containerd
install -m 755 ./containerd /usr/local/bin/containerd
containerd config default > /etc/containerd/config.toml

systemctl daemon-reexec
systemctl enable --now containerd

# 4. kubeadm, kubelet 설치
install -m 755 ./kubeadm /usr/bin/kubeadm
install -m 755 ./kubelet /usr/bin/kubelet

# kubelet systemd 설정
mkdir -p /etc/systemd/system/kubelet.service.d
cp ./10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 5. crictl 설정
cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF

# 6. CNI 구성
mkdir -p /opt/cni/bin /etc/cni/net.d
cp ./cni-plugins/* /opt/cni/bin/
cp ./10-flannel.conflist /etc/cni/net.d/

# 7. kubelet 시작
systemctl daemon-reexec
systemctl enable --now kubelet

echo "==== Worker 준비 완료 ===="
