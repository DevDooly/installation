#!/bin/bash

echo "===[ Kubernetes RunPodSandbox 문제 자동 진단 & 조치 ]==="

# 1. Check service status
echo -e "\n[1] 서비스 상태 확인:"
for svc in containerd kubelet; do
      status=$(systemctl is-active $svc)
          echo "$svc: $status"
              if [ "$status" != "active" ]; then
                        echo "→ $svc 서비스를 시작합니다..."
                                systemctl restart $svc
                                    fi
                                    done

# 2. Check image namespace (should be under k8s.io)
echo -e "\n[2] containerd 이미지 네임스페이스 확인:"
images=$(ctr -n k8s.io images ls | wc -l)
if [ "$images" -lt 2 ]; then
      echo "→ containerd(k8s.io)에 이미지가 없습니다. default namespace에 있는 이미지 가져옵니다."
          ctr -n default image ls | awk 'NR>1 {print $1}' | while read img; do
                  echo "→ 재등록: $img"
                          ctr -n default image export /tmp/tmpimg.tar $img
                                  ctr -n k8s.io image import /tmp/tmpimg.tar
                                          rm -f /tmp/tmpimg.tar
                                              done
                                              else
                                                    echo "→ 이미지가 정상적으로 존재합니다."
                                                    fi

# 3. CNI 존재 여부
echo -e "\n[3] CNI 설정 및 바이너리 확인:"
if [ ! -d /etc/cni/net.d ] || [ -z "$(ls -A /etc/cni/net.d 2>/dev/null)" ]; then
      echo "→ /etc/cni/net.d 설정 파일이 없습니다."
      else
            echo "→ CNI 설정 파일 있음:"
                ls /etc/cni/net.d
                fi

                if [ ! -d /opt/cni/bin ] || [ -z "$(ls -A /opt/cni/bin 2>/dev/null)" ]; then
                      echo "→ /opt/cni/bin 바이너리가 없습니다."
                      else
                            echo "→ CNI 바이너리 있음:"
                                ls /opt/cni/bin | head -n 5
                                fi

# 4. containerd SystemdCgroup 자동 패치
echo -e "\n[4] containerd config.toml의 SystemdCgroup 설정:"
CONFIG="/etc/containerd/config.toml"
if grep -q 'SystemdCgroup = false' $CONFIG; then
      echo "→ SystemdCgroup=false → true 로 변경합니다."
          sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' $CONFIG
              systemctl restart containerd
              else
                    echo "→ 설정 이미 올바르거나 존재하지 않음."
                    fi

# 5. static pod manifest 확인
echo -e "\n[5] Static Pod Manifest (/etc/kubernetes/manifests):"
ls /etc/kubernetes/manifests/*.yaml 2>/dev/null || echo "→ static pod이 존재하지 않습니다!"

# 6. containerd/kubelet 최근 로그
echo -e "\n[6] containerd 최근 에러 로그:"
journalctl -u containerd -n 10 --no-pager | grep -i error

echo -e "\n[7] kubelet 최근 에러 로그:"
journalctl -u kubelet -n 10 --no-pager | grep -i error

echo -e "\n[완료] 필요 시 crictl logs, ctr logs, manifest 확인 후 수동 조치 바랍니다."
