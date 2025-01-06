#!/bin/bash

# MariaDB 연결 정보 설정
DB_HOST="localhost"
DB_USER="skeleton"
DB_PASSWORD="skeleton"

# SQL 파일 확인
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <sql_file>"
    exit 1
fi

SQL_FILE=$1

if [ ! -f "$SQL_FILE" ]; then
    echo "Error: File '$SQL_FILE' does not exist."
    exit 1
fi

# SQL 파일 실행
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" < "$SQL_FILE"

if [ $? -eq 0 ]; then
    echo "SQL script executed successfully."
else
    echo "Failed to execute SQL script."
fi
