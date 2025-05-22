cat << 'EOF' > /root/k8s/2_check_k8s_status.sh
#!/bin/bash

echo "=== [Kubelet Status] ==="
systemctl status kubelet --no-pager | grep -E 'Loaded:|Active:|Main PID|status='

echo ""
echo "=== [Kubelet Logs - Recent Errors] ==="
journalctl -u kubelet -n 30 --no-pager | grep -iE "error|fail|panic" || echo "No recent errors found."

echo ""
echo "=== [Static Pod Status (crictl)] ==="
which crictl >/dev/null 2>&1 && crictl ps -a || echo "crictl not found. Please install it first."

echo ""
echo "=== [Static Pod YAMLs] ==="
ls -l /etc/kubernetes/manifests/

echo ""
echo "=== [Containerd Images] ==="
ctr -n k8s.io images ls
EOF
