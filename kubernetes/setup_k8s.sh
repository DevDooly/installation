#!/bin/bash
set -e

# 작업내용 1: 시스템 준비
cat <<'EOF' > /tmp/1_prepare_system.sh
#!/bin/bash
dnf install -y epel-release
dnf install -y iproute-tc vim net-tools bash-completion nfs-utils curl wget device-mapper-persistent-data lvm2

modprobe br_netfilter
cat <<EOT > /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOT

cat <<EOT > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOT
sysctl --system
EOF
chmod +x /tmp/1_prepare_system.sh
/tmp/1_prepare_system.sh

# 작업내용 2: containerd 수동 설치
cat <<'EOF' > /tmp/2_install_containerd.sh
#!/bin/bash

# tar.gz 경로는 사전 지정되어 있다고 가정
CONTAINERD_TAR="/root/containerd-1.7.15-linux-amd64.tar.gz"

if [ ! -f "$CONTAINERD_TAR" ]; then
    echo "[오류] containerd tar.gz 파일이 $CONTAINERD_TAR 에 존재하지 않습니다."
      exit 1
      fi

      tar Cxzvf /usr/local "$CONTAINERD_TAR"

# systemd 서비스 파일 복사
mkdir -p /usr/local/lib/systemd/system
cp /root/containerd.service /usr/local/lib/systemd/system/containerd.service

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now containerd
EOF
chmod +x /tmp/2_install_containerd.sh
/tmp/2_install_containerd.sh

# 작업내용 3: Kubernetes 바이너리 설치
cat <<'EOF' > /tmp/3_install_kubernetes.sh
#!/bin/bash
cat <<EOT > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=file:///root/k8s-rpms
enabled=1
gpgcheck=0
EOT

dnf install -y kubelet-1.33.0 kubeadm-1.33.0 kubectl-1.33.0
systemctl enable --now kubelet
EOF
chmod +x /tmp/3_install_kubernetes.sh
/tmp/3_install_kubernetes.sh

# 작업내용 4: kubeadm init 으로 클러스터 초기화
cat <<'EOF' > /tmp/4_kubeadm_init.sh
#!/bin/bash
kubeadm init --kubernetes-version=1.33.0 --pod-network-cidr=10.244.0.0/16 --upload-certs --ignore-preflight-errors=NumCPU

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
EOF
chmod +x /tmp/4_kubeadm_init.sh
/tmp/4_kubeadm_init.sh

# 작업내용 5: CNI 플러그인 적용
cat <<'EOF' > /tmp/5_apply_cni.sh
#!/bin/bash
kubectl apply -f /root/k8s-images/kube-flannel.yml
kubectl get nodes -o wide
EOF
chmod +x /tmp/5_apply_cni.sh
/tmp/5_apply_cni.sh

echo "[완료] Kubernetes v1.33.0 설치 및 클러스터 초기화가 완료되었습니다."
