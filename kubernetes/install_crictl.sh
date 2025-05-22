cat << 'EOF' > /root/k8s/1_install_crictl.sh
#!/bin/bash

set -e

# 설치할 버전 (containerd와 호환되는 안정 버전)
VERSION="v1.29.0"
ARCH="amd64"
OS="linux"

# 다운로드 및 설치
echo "[INFO] Downloading crictl $VERSION..."
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-${OS}-${ARCH}.tar.gz

echo "[INFO] Extracting..."
tar -C /usr/local/bin -xzf crictl-${VERSION}-${OS}-${ARCH}.tar.gz

echo "[INFO] Creating config file for containerd..."
mkdir -p /etc/crictl
cat << EOF_CONF > /etc/crictl/config.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF_CONF

echo "[INFO] Done. crictl installed at /usr/local/bin/crictl"
crictl --version
EOF
