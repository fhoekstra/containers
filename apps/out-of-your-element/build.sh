#!/usr/bin/env sh
set -eu

IMAGE=ghcr.io/fhoekstra/out-of-your-element
UPSTREAM=https://git.shork.ch/mirrors/out-of-your-element

FORCE=0

NEWEST_VERSION=$(curl -fsSL 'https://git.shork.ch/api/v1/repos/mirrors/out-of-your-element/tags?limit=1' | jq -r '.[0].name')
echo "Target: $IMAGE:$NEWEST_VERSION"

if [ -z "${CR_PAT:-}" ]; then
  echo "CR_PAT is not set, export it first (needed to log in to ghcr.io)" >&2
  exit 1
fi

echo "$CR_PAT" | sudo docker login ghcr.io -u fhoekstra --password-stdin

if [ "$FORCE" -ne 1 ] && sudo docker manifest inspect "$IMAGE:$NEWEST_VERSION" >/dev/null 2>&1; then
  echo "$NEWEST_VERSION is already published, nothing to do (use --force to rebuild)"
  exit 0
fi

sudo docker buildx rm multiarch 2>/dev/null || true
sudo docker buildx create --name multiarch --driver docker-container --driver-opt network=host --use
sudo docker buildx inspect --bootstrap

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
git clone --depth 1 --branch "$NEWEST_VERSION" "$UPSTREAM" "$TMP_DIR/src"

sudo docker buildx build "$TMP_DIR/src" \
  --file ./Containerfile \
  --platform linux/amd64,linux/arm64 \
  -t "$IMAGE:$NEWEST_VERSION" \
  -t "$IMAGE:latest" \
  --push

echo "Pushed $IMAGE:$NEWEST_VERSION and $IMAGE:latest"
