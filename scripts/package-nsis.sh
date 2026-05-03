#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}

# Check if running on Windows
if [ "$(uname -s)" != "MINGW"* ] && [ "$(uname -s)" != "MSYS"* ] && [ "$(uname -s)" != "Windows" ]; then
    echo "Error: NSIS packaging requires Windows runner"
    exit 1
fi

echo "Building NSIS installer for version ${VERSION}..."

# Install NSIS if not present
if ! command -v makensis &> /dev/null; then
    echo "Installing NSIS..."
    choco install nsis -y
fi

# Create build directory
mkdir -p nsis-build
cp "bin/asika-windows-amd64.exe" nsis-build/asika.exe 2>/dev/null || true
cp "bin/asikad-windows-amd64.exe" nsis-build/asikad.exe 2>/dev/null || true

# Copy NSIS script
cp templates/nsis/install.nsi nsis-build/

# Replace version in NSIS script
cd nsis-build
sed -i "s/1.0.0/${VERSION}/g" install.nsi

# Compile NSIS installer
makensis install.nsi

# Move output to dist/
mkdir -p ../dist
mv Asika_Setup_*.exe "../dist/asika-${VERSION}-setup.exe" 2>/dev/null || \
mv *.exe "../dist/asika-${VERSION}-setup.exe" 2>/dev/null || true

cd ..

echo "NSIS installer created:"
ls -lh dist/*.exe 2>/dev/null || echo "Warning: No installer found"
