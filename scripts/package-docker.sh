#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-asika}"
GITHUB_TOKEN="${GITHUB_TOKEN}"
GITHUB_ACTOR="${GITHUB_ACTOR}"

echo "Building Docker images for version ${VERSION}..."

# Setup QEMU for multi-architecture
echo "Setting up QEMU..."
docker run --rm --privileged docker/binfmt:latest

# Create and use buildx builder
docker buildx create --name multiarch --use --bootstrap 2>/dev/null || \
docker buildx use multiarch 2>/dev/null || \
docker buildx create --use

# Login to registry
if [ -n "$GITHUB_TOKEN" ]; then
    echo "$GITHUB_TOKEN" | docker login "${DOCKER_REGISTRY}" -u "${GITHUB_ACTOR:-oauth2accesstoken}" --password-stdin
fi

# Build and push multi-architecture image
# Only linux/amd64 and linux/arm64 are supported in ghcr.io
echo "Building and pushing Docker images..."
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest" \
    --tag "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${VERSION}" \
    --push \
    .

echo "Docker images pushed:"
echo "  ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest"
echo "  ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${VERSION}"
