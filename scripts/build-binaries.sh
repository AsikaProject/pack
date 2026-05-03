#!/bin/bash
set -e

GO_VERSION="${GO_VERSION:-1.25.0}"
BINARIES="${BINARIES:-asika,asikad}"
TAG_NAME="${TAG_NAME:-dev}"
WORKSPACE="${GITHUB_WORKSPACE:-.}"

echo "Building binaries with Go ${GO_VERSION}..."

# Check if Go is available, if not try to install it
if ! command -v go &> /dev/null; then
    echo "Go not found, downloading Go ${GO_VERSION}..."
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
    tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    rm /tmp/go.tar.gz
else
    echo "Go already installed: $(go version)"
fi

# Platforms to build
PLATFORMS="linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64"

# Create output directory
mkdir -p "${WORKSPACE}/bin"

for platform in $PLATFORMS; do
    GOOS=${platform%/*}
    GOARCH=${platform#*/}
    
    for binary in ${BINARIES//,/ }; do
        output_name="${binary}-${GOOS}-${GOARCH}"
        
        # Handle special cases
        if [ "$GOARCH" = "armhf" ]; then
            export GOARCH=arm
            export GOARM=7
            output_name="${binary}-${GOOS}-armhf"
        fi
        
        # Windows binaries need .exe extension
        if [ "$GOOS" = "windows" ]; then
            output_name="${output_name}.exe"
        fi
        
        echo "Building ${binary} for ${GOOS}/${GOARCH}..."
        
        # Build
        cd "${WORKSPACE}"
        GOOS=$GOOS GOARCH=$GOARCH go build -ldflags="-s -w -X 'asika/common/version.Version=${TAG_NAME}'" \
            -o "${WORKSPACE}/bin/${output_name}" ./cmd/"${binary}"
        
        # Reset GOARM if set
        if [ "$GOARCH" = "arm" ]; then
            unset GOARM
            export GOARCH=armhf
        fi
    done
done

echo "Build complete. Binaries in bin/:"
ls -lh "${WORKSPACE}/bin/"

# Create tar.gz for each binary
cd "${WORKSPACE}/bin"
for f in *; do
    # Skip directories and already-compressed files
    if [ -f "$f" ] && [[ "$f" != *.tar.gz ]]; then
        echo "Creating ${f}.tar.gz..."
        tar -czf "${f}.tar.gz" "$f"
    fi
done
cd "${WORKSPACE}"

echo "Tar.gz files created:"
ls -lh "${WORKSPACE}"/bin/*.tar.gz 2>/dev/null || echo "No tar.gz files found"
