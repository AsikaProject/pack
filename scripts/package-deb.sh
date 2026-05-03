#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}

echo "Building DEB packages for version ${VERSION}..."

# Create build directory
BUILD_DIR="/build/asika-${VERSION}"
mkdir -p /build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy current directory to build dir
cp -r . "$BUILD_DIR/"

cd "$BUILD_DIR"

# Replace /usr/local with /usr in service files
echo "Replacing /usr/local with /usr in templates..."
sed -i 's|/usr/local|/usr|g' templates/service/*

# Update changelog version
sed -i "s/0.0.0-1/${VERSION}-1/" debian/changelog

echo "Building DEB packages..."

# Build in Docker container
docker run --rm \
    -v /build:/build \
    -w "$BUILD_DIR" \
    debian:stable \
    bash -c "apt-get update && apt-get install -y debhelper-compat golang-go && dpkg-buildpackage -b -us -uc"

# Move .deb files to dist/
mkdir -p "${GITHUB_WORKSPACE:-.}/dist/"
mv /build/*.deb "${GITHUB_WORKSPACE:-.}/dist/"

echo "DEB packages created:"
ls -lh dist/*.deb
