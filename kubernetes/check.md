좋습니다. 아래는 Kubernetes 폐쇄망 환경에서 RunPodSandbox 에러 발생 시, 주요 원인 4가지를 자동으로 진단해주는 셸 스크립트입니다.

#!/bin/bash
echo "===[ Containerd / Kubelet 상태 점검 스크립트 ]==="

# 1. containerd 상태
echo -e "\n[1] containerd 서비스 상태:"
systemctl is-active containerd && echo "containerd is running." || echo "containerd is NOT running!"

# 2. kubelet 상태
echo -e "\n[2] kubelet 서비스 상태:"
systemctl is-active kubelet && echo "kubelet is running." || echo "kubelet is NOT running!"

# 3. containerd 네임스페이스에 이미지 존재 여부 확인
echo -e "\n[3] containerd(k8s.io namespace) 이미지 확인:"
if ! command -v ctr &> /dev/null; then
    echo "ctr 명령어가 없습니다. containerd 설치 확인 필요."
    else
        ctr -n k8s.io image ls
        fi

# 4. CNI 설정 파일 확인
echo -e "\n[4] CNI 설정 파일 존재 여부 (/etc/cni/net.d):"
if [ -d /etc/cni/net.d ]; then
    ls -1 /etc/cni/net.d
    else
        echo "/etc/cni/net.d 디렉토리가 없습니다. CNI 설정 필요!"
        fi

# 5. CNI 바이너리 확인
echo -e "\n[5] CNI 바이너리 존재 여부 (/opt/cni/bin):"
if [ -d /opt/cni/bin ]; then
    ls -1 /opt/cni/bin | head -n 5
    else
        echo "/opt/cni/bin 디렉토리가 없습니다. 바이너리 설치 필요!"
        fi

# 6. SystemdCgroup 설정 확인
echo -e "\n[6] containerd config.toml의 SystemdCgroup 설정 확인:"
config_file="/etc/containerd/config.toml"
if [ -f "$config_file" ]; then
    grep -A5 'runtimes.runc.options' "$config_file" | grep SystemdCgroup
    else
        echo "$config_file 파일이 없습니다."
        fi

# 7. static pod manifest 확인
echo -e "\n[7] Static Pod Manifest (/etc/kubernetes/manifests) 존재 여부:"
ls -1 /etc/kubernetes/manifests/*.yaml 2>/dev/null || echo "static pod 파일이 없습니다."

echo -e "\n[8] containerd 최신 에러 로그 보기:"
journalctl -u containerd -n 20 --no-pager

echo -e "\n[9] kubelet 최신 에러 로그 보기:"
journalctl -u kubelet -n 20 --no-pager


---

✅ 사용 방법

1. 위 내용을 예: check-k8s.sh 로 저장


2. 실행 권한 부여:



chmod +x check-k8s.sh

3. 실행:



./check-k8s.sh


---

필요 시 문제 해결 자동화까지 이어지는 버전도 제작 가능합니다. 원하시나요?


