#!/bin/bash
set -e

# 1. 이미지 가져오기
echo "[+] Pulling busybox:latest image..."
crictl pull docker.io/library/busybox:latest

# 2. PodSandbox 설정 파일 작성
echo "[+] Creating pod-config.json..."
cat <<EOF > pod-config.json
{
  "metadata": {
    "name": "busybox-pod",
    "namespace": "default",
    "uid": "busybox-pod-uid"
  },
  "log_directory": "/tmp",
  "linux": {}
}
EOF

# 3. PodSandbox 생성
echo "[+] Creating pod sandbox..."
SANDBOX_ID=$(crictl runp pod-config.json)
echo "    Sandbox ID: $SANDBOX_ID"

# 4. Container 설정 파일 작성
echo "[+] Creating container-config.json..."
cat <<EOF > container-config.json
{
  "metadata": {
    "name": "busybox-container"
  },
  "image": {
    "image": "docker.io/library/busybox:latest"
  },
  "command": [
    "sleep",
    "3600"
  ],
  "linux": {
    "security_context": {}
  }
}
EOF

# 5. 컨테이너 생성 및 시작
echo "[+] Creating container in sandbox..."
CONTAINER_ID=$(crictl create "$SANDBOX_ID" container-config.json pod-config.json)
echo "    Container ID: $CONTAINER_ID"

echo "[+] Starting container..."
crictl start "$CONTAINER_ID"

# 6. 상태 확인
echo "[+] Listing all containers..."
crictl ps -a
