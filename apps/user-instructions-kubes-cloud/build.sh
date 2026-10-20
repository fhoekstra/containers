#!/usr/bin/env sh
# Build and push the instructions site image (multiarch, like apps/*/build.sh)
set -eu

sudo docker buildx rm instructions-site-multiarch 2>/dev/null || true
sudo docker buildx create --name instructions-site-multiarch --driver docker-container --driver-opt network=host --use
sudo docker buildx inspect --bootstrap

echo $CR_PAT | sudo docker login ghcr.io -u fhoekstra --password-stdin

VERSION_TAG="$(date +%Y.%m.%d-%H%M)"
# --network host: this machine's docker has no working container DNS (Tailscale + systemd-resolved)
sudo docker buildx build . \
  --network host \
  --file ./Containerfile \
  --platform linux/amd64,linux/arm64 \
  --label org.opencontainers.image.revision="$(git rev-parse --short HEAD)" \
  -t ghcr.io/fhoekstra/instructions-site:latest \
  -t "ghcr.io/fhoekstra/instructions-site:${VERSION_TAG}" \
  --push
