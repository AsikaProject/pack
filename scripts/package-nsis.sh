#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}

# Convert YYYYMMDD[SUFFIX] to NSIS-compatible version
# Example: 20260503 -> 2.0.2.6
if [[ "$VERSION" =~ ^([0-9]{4}) ]]; then
    YEAR="${BASH_REMATCH[1]}"
    NSIS_VERSION="${YEAR:0:1}.${YEAR:1:1}.${YEAR:2:1}.${YEAR:3:1}"
else
    NSIS_VERSION="0.0.0.0"
fi

# Check if running on Windows
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*|Windows)
        echo "Running on Windows: $(uname -s)"
        ;;
    *)
        echo "Error: NSIS packaging requires Windows runner (current: $(uname -s))"
        exit 1
        ;;
esac

echo "Building NSIS installer for version ${VERSION} (NSIS version: ${NSIS_VERSION})..."

WORKSPACE="${GITHUB_WORKSPACE:-.}"

# Install NSIS if not present
if ! command -v makensis &> /dev/null; then
    echo "Installing NSIS via choco..."
    choco install nsis -y --no-progress --limit-output 2>&1 || true
    # Search for makensis in common install locations
    for dir in \
        "/c/ProgramData/chocolatey/bin" \
        "/c/ProgramData/chocolatey/lib/nsis" \
        "/c/ProgramData/chocolatey/lib/nsis/tools" \
        "/c/Program Files (x86)/NSIS/Bin" \
        "/c/Program Files (x86)/NSIS" \
        "/c/Program Files/NSIS/Bin" \
        "/c/Program Files/NSIS"; do
        if [ -f "$dir/makensis.exe" ]; then
            export PATH="$dir:$PATH"
            echo "Found makensis at: $dir/makensis.exe"
            break
        fi
    done
fi

if ! command -v makensis &> /dev/null; then
    echo "Error: makensis not found"
    exit 1
fi

# Create build directory
mkdir -p nsis-build
cp "${WORKSPACE}/bin/asika-windows-amd64.exe" nsis-build/asika.exe 2>/dev/null || true
cp "${WORKSPACE}/bin/asikad-windows-amd64.exe" nsis-build/asikad.exe 2>/dev/null || true
cp "${WORKSPACE}/pack/LICENSE" nsis-build/LICENSE
cp "${WORKSPACE}/pack/templates/nsis/asika.ico" nsis-build/
cp "${WORKSPACE}/pack/templates/nsis/header.bmp" nsis-build/
cp "${WORKSPACE}/pack/templates/nsis/welcome.bmp" nsis-build/

# Copy documentation
mkdir -p nsis-build/doc
if [ -f "${WORKSPACE}/pack/doc/asika.html" ]; then
    cp "${WORKSPACE}/pack/doc/asika.html" nsis-build/doc/
fi
if [ -f "${WORKSPACE}/pack/doc/asikad.html" ]; then
    cp "${WORKSPACE}/pack/doc/asikad.html" nsis-build/doc/
fi
if [ -f "${WORKSPACE}/pack/doc/asika.1" ]; then
    cp "${WORKSPACE}/pack/doc/asika.1" nsis-build/doc/
fi
if [ -f "${WORKSPACE}/pack/doc/asikad.1" ]; then
    cp "${WORKSPACE}/pack/doc/asikad.1" nsis-build/doc/
fi

# Copy NSIS script
cp "${WORKSPACE}/pack/templates/nsis/install.nsi" nsis-build/

# Replace version in NSIS script (0.0.0.0 is placeholder)
cd nsis-build
sed -i "s/0.0.0.0/${NSIS_VERSION}/g" install.nsi

# Compile NSIS installer
makensis install.nsi

# Move output to dist/
mkdir -p ../dist
mv Asika_Setup_*.exe "../dist/asika-${VERSION}-setup.exe" 2>/dev/null || \
mv ./*.exe "../dist/asika-${VERSION}-setup.exe" 2>/dev/null || true

cd ..

echo "NSIS installer created:"
ls -lh dist/*.exe 2>/dev/null || echo "Warning: No installer found"
