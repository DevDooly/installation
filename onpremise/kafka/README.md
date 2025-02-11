# KAFKA

## 설치 목록
* KAFKA
* KAFKA MANAGER (CMAK)

## 설치 방법
* ansible-playbook -i inventory/hosts main.yml -v

## 업그레이드
1. upgrade_kafka_pre 단독 실행inter.broker.protocol.version 변경 (기존 버전으로)
    - upgrade_kafka_pre 실행 후 서버의 server.properties 변경 확인
2. upgrade_kafka 진행
   * 
2. 
3. 

## zookeeper -> kraft migration
* ansible-playbook -i inventory/hosts migration.yml -v