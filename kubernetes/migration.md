# System Migration

| 기능 / 영역 | Hadoop 기반 (AS-IS) | K8S 기반 (TO-BE)|
|-|-|-|
|컴퓨팅 엔진|YARN, MapReduce, Tez, Spark On Yarn|Spark, Trino On K8S|
|워크플로우 오케스트레이션|Airflow(2.x)|Airflow(3.x), Argo Workflows|
|스토리지|HDFS|Object Storage(MinIO, Ceph, S3), PVC Longhorn(Block Storage)|
|데이터 포맷|ORC, Parquet|Parquet|
|메타데이터 카탈로그|Hive Metastore|Iceberg REST Catalog, Nessie, Glue|
|데이터 쿼리 엔진|Hive, Trino|Trino|
|데이터 수집 / 적재|Spark, Hive(Tez, MR)|Spark|
|권한 관리 / 보안|LDAP|LDAP, OPA|
|모니터링 / 로깅|Grafana|Prometheus, Grafana, Fluent Bit|
|리소스 관리|YARN|Kubernetes Scheduler, younicon|
|배포 / 관리 / 형상관리 툴|Ansible, Bitbucket|Helm, ArgoCD, Ansible, Kubespray, Bitbucket|
|데이터 메타 관리|Hive Metastore(Oracle)|Hive Metastore(Oracle)|
|UI 및 ETL 연결|Trino JDBC, ODBC|Trino JDBC|
