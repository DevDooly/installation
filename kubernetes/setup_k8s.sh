#!/bin/bash
set -e

# 작업내용 1: 필수 패키지 및 커널 설정
cat <<'EOF' > /tmp/step1_prepare_system.sh
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
chmod +x /tmp/step1_prepare_system.sh
/tmp/step1_prepare_system.sh

# 작업내용 2: containerd 설치 및 설정
cat <<'EOF' > /tmp/step2_install_containerd.sh
#!/bin/bash
dnf install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd
EOF
chmod +x /tmp/step2_install_containerd.sh
/tmp/step2_install_containerd.sh

# 작업내용 3: kubeadm, kubelet, kubectl 설치
cat <<'EOF' > /tmp/step3_install_kubernetes.sh
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
chmod +x /tmp/step3_install_kubernetes.sh
/tmp/step3_install_kubernetes.sh

# 작업내용 4: kubeadm init 으로 클러스터 초기화
cat <<'EOF' > /tmp/step4_kubeadm_init.sh
#!/bin/bash
kubeadm init --kubernetes-version=1.33.0 --pod-network-cidr=10.244.0.0/16 --upload-certs --ignore-preflight-errors=NumCPU

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
EOF
chmod +x /tmp/step4_kubeadm_init.sh
/tmp/step4_kubeadm_init.sh

# 작업내용 5: CNI (예: flannel) 적용 및 확인
cat <<'EOF' > /tmp/step5_apply_cni.sh
#!/bin/bash
kubectl apply -f /root/k8s-images/kube-flannel.yml
kubectl get nodes -o wide
EOF
chmod +x /tmp/step5_apply_cni.sh
/tmp/step5_apply_cni.sh

echo "[완료] Kubernetes v1.33.0 설치 및 초기화가 완료되었습니다."
