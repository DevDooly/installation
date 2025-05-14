#!/bin/bash
# harbor_images_download.sh

# Harbor 이미지 버전 (예: 2.10.0, 확인 필요)
VERSION="v2.10.0"

# 이미지 목록
IMAGES=(
  goharbor/harbor-core
    goharbor/harbor-db
      goharbor/harbor-jobservice
        goharbor/harbor-portal
          goharbor/harbor-registry
            goharbor/nginx-photon
              goharbor/redis-photon
                goharbor/registry-photon
                  goharbor/trivy-adapter
                    goharbor/harbor-exporter
                    )

mkdir -p harbor-images

for image in "${IMAGES[@]}"; do
    full_image="${image}:${VERSION}"
      echo "Pulling $full_image..."
        docker pull "$full_image"
          echo "Saving $full_image..."
            docker save -o "harbor-images/$(echo $image | cut -d'/' -f2).tar" "$full_image"
            done

            echo "모든 이미지 저장 완료: harbor-images/"

tar -cf harbor-images.tar harbor-images/*
