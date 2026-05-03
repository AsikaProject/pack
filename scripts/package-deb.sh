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

# Build in Docker to ensure correct environment
echo "Building DEB packages in Docker..."
docker run --rm \
    -v "${WORKSPACE}:/workspace" \
    -w "/workspace" \
    debian:stable \
    bash -c "apt-get update && apt-get install -y debhelper-compat golang-go && \
             cp -r pack/debian . && \
             dpkg-buildpackage -b -us -uc 2>&1"

# Move .deb files to dist/
mkdir -p "${WORKSPACE}/dist/"
mv "${WORKSPACE}"/../*.deb "${WORKSPACE}/dist/" 2>/dev/null || \
find / -name "*.deb" -path "*/workspace/*" -exec mv {} "${WORKSPACE}/dist/" \; 2>/dev/null || true

echo "DEB packages created:"
ls -lh "${WORKSPACE}/dist/"*.deb 2>/dev/null || echo "Warning: No .deb files found"
