#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-asika}"
GITHUB_TOKEN="${GITHUB_TOKEN}"
GITHUB_ACTOR="${GITHUB_ACTOR}"
CONTEXT_DIR="${CONTEXT_DIR:-.}"

echo "Building Docker images for version ${VERSION}..."
echo "Context directory: ${CONTEXT_DIR}"

# Setup QEMU for multi-architecture
echo "Setting up QEMU..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Create and use buildx builder
docker buildx create --name multiarch --driver docker-container --use 2>/dev/null || \
docker buildx use multiarch 2>/dev/null || true

docker buildx inspect --bootstrap

# Login to registry
if [ -n "$GITHUB_TOKEN" ]; then
    echo "Logging in to ${DOCKER_REGISTRY}..."
    echo "$GITHUB_TOKEN" | docker login "${DOCKER_REGISTRY}" -u "${GITHUB_ACTOR:-oauth2accesstoken}" --password-stdin
fi

# Build and push multi-architecture image
# Only linux/amd64 and linux/arm64 are supported in ghcr.io
echo "Building and pushing Docker images..."
docker buildx build \
    --build-arg VERSION=${VERSION} \
    --platform linux/amd64,linux/arm64 \
    --file "${CONTEXT_DIR}/pack/Dockerfile" \
    --tag "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest" \
    --tag "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${VERSION}" \
    --push \
    "${CONTEXT_DIR}"

echo "Docker images pushed:"
echo "  ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest"
echo "  ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${VERSION}"
