#!/bin/bash
set -e

LONGHORN_VERSION="v1.8.1"
REGISTRY_DIR="longhorn-images"
YAML_DIR="longhorn-yamls"

mkdir -p ${REGISTRY_DIR} ${YAML_DIR}

# 1. YAML 다운로드
curl -Lo ${YAML_DIR}/longhorn.yaml https://raw.githubusercontent.com/longhorn/longhorn/${LONGHORN_VERSION}/deploy/longhorn.yaml

# 2. YAML에서 사용되는 이미지 추출
IMAGES=$(grep -oP '(?<=image: ).*' ${YAML_DIR}/longhorn.yaml | sort -u)

# 3. 이미지 저장
for IMAGE in ${IMAGES}; do
  echo "Pulling $IMAGE"
  nerdctl pull "$IMAGE"
  echo "Saving $IMAGE"
  IMAGE_NAME=$(echo $IMAGE | tr '/:' '_')
  nerdctl save -o ${REGISTRY_DIR}/${IMAGE_NAME}.tar $IMAGE
done

# 4. 번들 압축
tar czf longhorn-${LONGHORN_VERSION}.tar.gz ${REGISTRY_DIR} ${YAML_DIR}
echo "완료: longhorn-${LONGHORN_VERSION}.tar.gz"
