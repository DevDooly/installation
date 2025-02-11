#!/bin/bash

sudo apt update

# MariaDB 공식 래포
sudo apt install -y software-properties-common gnupg

# MariaDB 래포 설정
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash

# 설치
sudo apt install -y mariadb-server

# 상태 확인
sudo systemctl status mariadb

# 보안 설정
# sudo mysql_secure_installation
