#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}
WORKSPACE="${GITHUB_WORKSPACE:-.}"

echo "Building DEB packages for version ${VERSION}..."

# Update changelog version
if [ -f "${WORKSPACE}/pack/debian/changelog" ]; then
    sed -i "s/0.0.0-1/${VERSION}-1/" "${WORKSPACE}/pack/debian/changelog"
fi

# Replace /usr/local with /usr in service templates
if [ -d "${WORKSPACE}/pack/templates/service" ]; then
    sed -i 's|/usr/local|/usr|g' "${WORKSPACE}/pack/templates/service/"* 2>/dev/null || true
fi

# Create build subdirectory so .deb goes to parent (inside mounted volume)
BUILD_SUBDIR="${WORKSPACE}/deb-build"
rm -rf "$BUILD_SUBDIR"
mkdir -p "$BUILD_SUBDIR"

# Copy binaries and pack files to build dir
cp "${WORKSPACE}/asika" "$BUILD_SUBDIR/" 2>/dev/null || true
cp "${WORKSPACE}/asikad" "$BUILD_SUBDIR/" 2>/dev/null || true
cp -r "${WORKSPACE}/pack/debian" "$BUILD_SUBDIR/"
cp -r "${WORKSPACE}/pack/templates" "$BUILD_SUBDIR/"
cp -r "${WORKSPACE}/pack/doc" "$BUILD_SUBDIR/"

# Build in Docker
echo "Building DEB packages in Docker..."
docker run --rm \
    -v "${WORKSPACE}:/workspace" \
    -w "/workspace/deb-build" \
    debian:sid \
    bash -c "apt-get update && apt-get install -y debhelper-compat golang-go && \
             go version && \
             dpkg-buildpackage -b -us -uc 2>&1"

# .deb files go to parent dir of build subdir (= /workspace/)
mkdir -p "${WORKSPACE}/dist/"
mv "${WORKSPACE}"/*.deb "${WORKSPACE}/dist/" 2>/dev/null || true

echo "DEB packages created:"
ls -lh "${WORKSPACE}/dist/"*.deb 2>/dev/null || echo "Warning: No .deb files found"