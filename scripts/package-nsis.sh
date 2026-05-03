#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}

# Convert YYYYMMDD[SUFFIX] to NSIS-compatible version (use first 4 digits: YYYY -> Y.Y.Y.Y)
# Example: 20260503DEV -> 2.0.2.6 (take first 4 digits of YYYYMMDD)
if [[ "$VERSION" =~ ^([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
    NSIS_VERSION="${BASH_REMATCH[1]:0:1}.${BASH_REMATCH[1]:1:1}.${BASH_REMATCH[1]:2:1}.${BASH_REMATCH[1]:3:1}"
else
    NSIS_VERSION="0.0.0.0"
fi

# Check if running on Windows
if [ "$(uname -s)" != "MINGW"* ] && [ "$(uname -s)" != "MSYS"* ] && [ "$(uname -s)" != "Windows" ]; then
    echo "Error: NSIS packaging requires Windows runner"
    exit 1
fi

echo "Building NSIS installer for version ${VERSION} (NSIS version: ${NSIS_VERSION})..."

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

# Replace version in NSIS script (0.0.0.0 is placeholder)
cd nsis-build
sed -i "s/0.0.0.0/${NSIS_VERSION}/g" install.nsi

# Compile NSIS installer
makensis install.nsi

# Move output to dist/
mkdir -p ../dist
mv Asika_Setup_*.exe "../dist/asika-${VERSION}-setup.exe" 2>/dev/null || \
mv *.exe "../dist/asika-${VERSION}-setup.exe" 2>/dev/null || true

cd ..

echo "NSIS installer created:"
ls -lh dist/*.exe 2>/dev/null || echo "Warning: No installer found"
