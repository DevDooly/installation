#!/bin/bash
set -e

LONGHORN_VERSION="v1.8.1"
ARCHIVE="longhorn-${LONGHORN_VERSION}.tar.gz"

# 1. 압축 해제
tar xzf ${ARCHIVE}

# 2. 이미지 로드
for IMAGE_TAR in longhorn-images/*.tar; do
  echo "Loading ${IMAGE_TAR}"
  nerdctl load -i "${IMAGE_TAR}"
done

# 3. Longhorn 설치
kubectl apply -f longhorn-yamls/longhorn.yaml

echo "Longhorn ${LONGHORN_VERSION} 설치 완료"
