#!/bin/bash
set -e

GO_VERSION="${GO_VERSION:-1.25.0}"
BINARIES="${BINARIES:-asika,asikad}"
TAG_NAME="${TAG_NAME:-dev}"

echo "Building binaries with Go ${GO_VERSION}..."

# Download and install Go
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
tar -C /usr/local -xzf /tmp/go.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm /tmp/go.tar.gz

# Platforms to build
PLATFORMS="linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64"

# Create output directory
mkdir -p bin

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
        cd "${GITHUB_WORKSPACE:-.}"
        GOOS=$GOOS GOARCH=$GOARCH go build -ldflags="-s -w" \
            -o "bin/${output_name}" ./cmd/${binary}
        
        # Reset GOARM if set
        if [ "$GOARCH" = "arm" ]; then
            unset GOARM
            export GOARCH=armhf
        fi
    done
done

echo "Build complete. Binaries in bin/:"
ls -lh bin/
