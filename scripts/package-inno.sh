#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}

# Convert YYYYMMDD[SUFFIX] to Inno Setup compatible version
# Example: 20260503 -> 2.0.2.6
if [[ "$VERSION" =~ ^([0-9]{4}) ]]; then
    YEAR="${BASH_REMATCH[1]}"
    INNO_VERSION="${YEAR:0:1}.${YEAR:1:1}.${YEAR:2:1}.${YEAR:3:1}"
else
    INNO_VERSION="0.0.0.0"
fi

# Check if running on Windows
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*|Windows)
        echo "Running on Windows: $(uname -s)"
        ;;
    *)
        echo "Error: Inno Setup packaging requires Windows runner (current: $(uname -s))"
        exit 1
        ;;
esac

echo "Building Inno Setup installer for version ${VERSION} (Inno version: ${INNO_VERSION})..."

WORKSPACE="${GITHUB_WORKSPACE:-.}"

# Install Inno Setup if not present
if ! command -v iscc &> /dev/null; then
    echo "Installing Inno Setup via choco..."
    choco install innosetup -y --no-progress --limit-output 2>&1 || true
    # Search for iscc in common install locations
    for dir in \
        "/c/ProgramData/chocolatey/bin" \
        "/c/Program Files (x86)/Inno Setup 6" \
        "/c/Program Files/Inno Setup 6" \
        "/c/Program Files (x86)/Inno Setup 5" \
        "/c/Program Files/Inno Setup 5"; do
        if [ -f "$dir/ISCC.exe" ]; then
            export PATH="$dir:$PATH"
            echo "Found ISCC at: $dir/ISCC.exe"
            break
        fi
    done
fi

if ! command -v iscc &> /dev/null; then
    echo "Error: iscc not found"
    exit 1
fi

# Create build directory
mkdir -p inno-build

# Copy binaries from current directory (already extracted by workflow)
cp asika.exe inno-build/ 2>/dev/null || true
cp asikad.exe inno-build/ 2>/dev/null || true

# Copy LICENSE file (from pack directory in GitHub Actions)
if [ -f "pack/LICENSE" ]; then
    cp "pack/LICENSE" inno-build/
elif [ -f "LICENSE" ]; then
    cp LICENSE inno-build/
else
    echo "Warning: LICENSE file not found, creating default..."
    echo "MIT License" > inno-build/LICENSE
    echo "" >> inno-build/LICENSE
    echo "Copyright (c) $(date +%Y) Asika Project" >> inno-build/LICENSE
fi

# Copy documentation
mkdir -p inno-build/doc
if [ -f "${WORKSPACE}/pack/doc/asika.html" ]; then
    cp "${WORKSPACE}/pack/doc/asika.html" inno-build/doc/
fi
if [ -f "${WORKSPACE}/pack/doc/asikad.html" ]; then
    cp "${WORKSPACE}/pack/doc/asikad.html" inno-build/doc/
fi
if [ -f "${WORKSPACE}/pack/doc/asika.1" ]; then
    cp "${WORKSPACE}/pack/doc/asika.1" inno-build/doc/
fi
if [ -f "${WORKSPACE}/pack/doc/asikad.1" ]; then
    cp "${WORKSPACE}/pack/doc/asikad.1" inno-build/doc/
fi

# Copy Inno Setup script
cp "${WORKSPACE}/pack/templates/inno/setup.iss" inno-build/

# Replace version in Inno Setup script (0.0.0.0 is placeholder)
cd inno-build
sed -i "s/0.0.0.0/${INNO_VERSION}/g" setup.iss

# Compile Inno Setup installer
iscc setup.iss

# Move output to dist/
cd ..
mkdir -p dist
mv inno-build/Asika_Setup_*.exe "dist/asika-${VERSION}-setup.exe" 2>/dev/null || \
mv inno-build/*.exe "dist/asika-${VERSION}-setup.exe" 2>/dev/null || true

echo "Inno Setup installer created:"
ls -lh dist/*.exe 2>/dev/null || echo "Warning: No installer found"
