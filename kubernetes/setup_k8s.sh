#!/bin/bash
set -e

mkdir -p /root/k8s

# 1_ 시스템 준비
cat <<'EOF' > /root/k8s/1_prepare_system.sh
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
chmod +x /root/k8s/1_prepare_system.sh
# /root/k8s/1_prepare_system.sh

# 2_ containerd 수동 설치
cat <<'EOF' > /root/k8s/2_install_containerd.sh
#!/bin/bash
CONTAINERD_TAR="/root/containerd-1.7.15-linux-amd64.tar.gz"
SERVICE_FILE="/root/containerd.service"

if [ ! -f "$CONTAINERD_TAR" ] || [ ! -f "$SERVICE_FILE" ]; then
    echo "[오류] containerd tar.gz 또는 service 파일이 없습니다."
      exit 1
      fi

      tar -C /usr/local -xzf "$CONTAINERD_TAR"

      mkdir -p /usr/local/lib/systemd/system
      cp "$SERVICE_FILE" /usr/local/lib/systemd/system/containerd.service

      systemctl daemon-reexec
      systemctl daemon-reload
      systemctl enable --now containerd

      mkdir -p /etc/containerd
      containerd config default > /etc/containerd/config.toml
      sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
      systemctl restart containerd
      EOF
      chmod +x /root/k8s/2_install_containerd.sh
# /root/k8s/2_install_containerd.sh

# 3_ Kubernetes 바이너리 수동 설치
cat <<'EOF' > /root/k8s/3_install_kubernetes.sh
#!/bin/bash
K8S_TAR="/root/kubernetes-server-linux-amd64.tar.gz"
K8S_BIN_DIR="/usr/local/bin"

if [ ! -f "$K8S_TAR" ]; then
    echo "[오류] Kubernetes tar.gz 파일이 $K8S_TAR 에 없습니다."
      exit 1
      fi

      tar -xzf "$K8S_TAR" -C /tmp
      cp /tmp/kubernetes/server/bin/kubeadm $K8S_BIN_DIR/
      cp /tmp/kubernetes/server/bin/kubectl $K8S_BIN_DIR/
      cp /tmp/kubernetes/server/bin/kubelet $K8S_BIN_DIR/
      chmod +x $K8S_BIN_DIR/kube*

      cat <<EOT > /etc/systemd/system/kubelet.service
      [Unit]
      Description=kubelet: The Kubernetes Node Agent
      Documentation=https://kubernetes.io/docs/
      After=network.target

      [Service]
      ExecStart=/usr/local/bin/kubelet
      Restart=always
      StartLimitInterval=0
      RestartSec=10

      [Install]
      WantedBy=multi-user.target
      EOT

      mkdir -p /etc/systemd/system/kubelet.service.d
      cat <<EOT > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
      [Service]
      Environment="KUBELET_KUBEADM_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
      EOT

      systemctl daemon-reexec
      systemctl daemon-reload
      systemctl enable --now kubelet
      EOF
      chmod +x /root/k8s/3_install_kubernetes.sh
# /root/k8s/3_install_kubernetes.sh

# 4_ 이미지 프리로드
cat <<'EOF' > /root/k8s/4_preload_images.sh
#!/bin/bash
IMAGE_DIR="/root/k8s-images"

if [ ! -d "$IMAGE_DIR" ]; then
    echo "[오류] 이미지 디렉터리가 존재하지 않습니다: $IMAGE_DIR"
      exit 1
      fi

      for img in "$IMAGE_DIR"/*.tar; do
          echo "Importing image: $img"
            ctr -n k8s.io images import "$img"
            done

            ctr -n k8s.io images ls
            EOF
            chmod +x /root/k8s/4_preload_images.sh
# /root/k8s/4_preload_images.sh

# 5_ kubeadm init
cat <<'EOF' > /root/k8s/5_kubeadm_init.sh
#!/bin/bash
kubeadm init --kubernetes-version=1.33.0 \
  --pod-network-cidr=192.168.0.0/16 \
    --upload-certs \
      --ignore-preflight-errors=NumCPU

      mkdir -p $HOME/.kube
      cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      chown $(id -u):$(id -g) $HOME/.kube/config
      EOF
      chmod +x /root/k8s/5_kubeadm_init.sh
# /root/k8s/5_kubeadm_init.sh

# 6_ Calico 적용
cat <<'EOF' > /root/k8s/6_apply_cni.sh
#!/bin/bash
CNI_FILE="/root/k8s-images/calico.yaml"

if [ ! -f "$CNI_FILE" ]; then
    echo "[오류] Calico CNI 설정 파일이 없습니다: $CNI_FILE"
      exit 1
      fi

      kubectl apply -f "$CNI_FILE"
      sleep 10
      kubectl get pods -A
      kubectl get nodes -o wide
      EOF
      chmod +x /root/k8s/6_apply_cni.sh
# /root/k8s/6_apply_cni.sh

      echo "[완료] 설치용 스크립트가 /root/k8s 에 모두 생성되었습니다."
      echo "[확인] 다음 파일들이 필요합니다:"
      echo "  - /root/containerd-1.7.15-linux-amd64.tar.gz"
      echo "  - /root/containerd.service"
      echo "  - /root/kubernetes-server-linux-amd64.tar.gz"
      echo "  - /root/k8s-images/*.tar (사전 다운로드된 이미지)"
      echo "  - /root/k8s-images/calico.yaml (Calico CNI 매니페스트)"
