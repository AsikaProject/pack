#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}
WORKSPACE="${GITHUB_WORKSPACE:-.}"

echo "Building DEB packages for version ${VERSION}..."

# Create build directory in workspace
BUILD_DIR="${WORKSPACE}/build/asika-${VERSION}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy asika source to build dir
echo "Copying source to build directory..."
cp -r "${WORKSPACE}/"* "$BUILD_DIR/" 2>/dev/null || true

# Copy debian directory from pack/ if it exists
if [ -d "${WORKSPACE}/pack/debian" ]; then
    echo "Using debian directory from pack/"
    cp -r "${WORKSPACE}/pack/debian" "$BUILD_DIR/"
else
    echo "Using debian directory from source"
fi

cd "$BUILD_DIR"

# Replace /usr/local with /usr in service files (if they exist)
if [ -d "templates/service" ]; then
    echo "Replacing /usr/local with /usr in templates..."
    sed -i 's|/usr/local|/usr|g' templates/service/* 2>/dev/null || true
fi

# Update changelog version
if [ -f "debian/changelog" ]; then
    sed -i "s/0.0.0-1/${VERSION}-1/" debian/changelog
fi

echo "Building DEB packages..."

# Build Debian packages
dpkg-buildpackage -b -us -uc 2>&1 || {
    echo "Error: dpkg-buildpackage failed"
    echo "Install debhelper: apt-get install -y debhelper-compat"
    exit 1
}

# Move .deb files to dist/
mkdir -p "${WORKSPACE}/dist/"
mv "${WORKSPACE}"/build/*.deb "${WORKSPACE}/dist/" 2>/dev/null || \
mv "${BUILD_DIR}"/../*.deb "${WORKSPACE}/dist/" 2>/dev/null || \
find / -name "*.deb" -exec mv {} "${WORKSPACE}/dist/" \; 2>/dev/null || true

echo "DEB packages created:"
ls -lh "${WORKSPACE}/dist/"*.deb 2>/dev/null || echo "Warning: No .deb files found"
