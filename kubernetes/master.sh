#!/bin/bash

MASTER_HOSTNAME=rhel01

# set hostname
hostnamectl set-hostname $MASTER_HOSTNAME

## vmware

## set repo
cat <<EOT > /etc/yum.repos.d/rhel.repo
[rhel-BaseOS]
name=Red Hat Enterprise LInux $releasever - $basearch - BaseOS
baseurl=file:///media/BaseOS/
gpgcheck=0
Enabled=1

[rhel-AppStream]
name=Red Hat Enterprise Linux $releasever - $basearch - AppStream
baseurl=file:///media/AppStream/
gpgcheck=0
Enabled=1
EOT

yum update

## 필수 패키지
dnf install -y iproute-tc vim net-tools bash-completion nfs-utils curl wget device-mapper-persistent-data lvm2

## 초기설정

## swap 메모리
swapoff -a
sed -i.bak '/ swap /s/^/#/' /etc/fstab

## 방화벽
systemctl stop firewalld
systemctl eisable firewalld

## selinux
setenforce 0 
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

## 
modprobe br_netfilter
cat <<EOT > /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOT

cat <<EOT > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOT
sysctl --system

## containerd

## runc

## crictl


