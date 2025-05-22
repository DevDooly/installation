cat <<'EOF' > /root/k8s/6_configure_cni_check.sh
#!/bin/bash
set -e

echo "[1] CNI 바이너리 확인 및 설치..."
if [ ! -d /opt/cni/bin ]; then
  mkdir -p /opt/cni/bin
fi

if [ ! -f /opt/cni/bin/bridge ]; then
  if [ -f /root/k8s/cni-plugins-linux-amd64-v1.4.0.tgz ]; then
    tar -xzf /root/k8s/cni-plugins-linux-amd64-v1.4.0.tgz -C /opt/cni/bin
  else
    echo "[ERROR] CNI 바이너리가 없습니다: /root/k8s/cni-plugins-linux-amd64-v1.4.0.tgz"
    exit 1
  fi
fi

echo "[2] CNI 설정파일 생성..."
mkdir -p /etc/cni/net.d
cat <<EOF2 > /etc/cni/net.d/10-bridge.conf
{
  "cniVersion": "0.4.0",
  "name": "bridge",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.10.0.0/16",
    "routes": [
      { "dst": "0.0.0.0/0" }
    ]
  }
}
EOF2

echo "[3] loopback 설정 확인..."
cat <<EOF3 > /etc/cni/net.d/99-loopback.conf
{
  "cniVersion": "0.4.0",
  "type": "loopback"
}
EOF3

echo "[4] kubelet 재시작..."
systemctl daemon-reexec
systemctl restart kubelet

echo "[5] 10초간 대기 후 CNI 초기화 상태 확인..."
sleep 10
crictl info | grep -A4 '"status"' | grep -i network

echo "[완료] 위 결과에서 'networkReady: true' 가 확인되어야 정상입니다."
EOF

chmod +x /root/k8s/6_configure_cni_check.sh
