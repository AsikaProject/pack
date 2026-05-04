#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}
WORKSPACE="${GITHUB_WORKSPACE:-.}"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Error: PKG packaging requires macOS runner"
    exit 1
fi

echo "Building PKG installer for version ${VERSION}..."

# Determine architecture
if [ -f "bin/asikad-darwin-amd64" ]; then
    BINARY="bin/asikad-darwin-amd64"
    ARCH="amd64"
elif [ -f "bin/asikad-darwin-arm64" ]; then
    BINARY="bin/asikad-darwin-arm64"
    ARCH="arm64"
else
    echo "Error: No asikad binary found for macOS"
    exit 1
fi

# Create payload directory structure
ROOT_DIR="$(pwd)/pkg-root"
rm -rf "$ROOT_DIR"
mkdir -p "$ROOT_DIR/usr/local/bin"
mkdir -p "$ROOT_DIR/Library/LaunchDaemons"

# Copy binary
cp "$BINARY" "$ROOT_DIR/usr/local/bin/asikad"
chmod 755 "$ROOT_DIR/usr/local/bin/asikad"

# Copy documentation
mkdir -p "$ROOT_DIR/usr/local/share/doc/asika"
if [ -f "${WORKSPACE}/pack/doc/asikad.html" ]; then
    cp "${WORKSPACE}/pack/doc/asikad.html" "$ROOT_DIR/usr/local/share/doc/asika/"
fi
if [ -f "${WORKSPACE}/pack/doc/asika.html" ]; then
    cp "${WORKSPACE}/pack/doc/asika.html" "$ROOT_DIR/usr/local/share/doc/asika/"
fi

# Copy and fix LaunchDaemon plist from pack templates
PLIST_TEMPLATE="${WORKSPACE}/pack/templates/service/com.asika.daemon.plist"
if [ -f "$PLIST_TEMPLATE" ]; then
    cp "$PLIST_TEMPLATE" "$ROOT_DIR/Library/LaunchDaemons/com.asika.daemon.plist"
    /usr/libexec/PlistBuddy -c "Set :Program /usr/local/bin/asikad" \
        "$ROOT_DIR/Library/LaunchDaemons/com.asika.daemon.plist" 2>/dev/null || true
fi

# Create postinstall script
SCRIPTS_DIR=$(mktemp -d)
cat > "$SCRIPTS_DIR/postinstall" <<'POSTINSTALL'
#!/bin/bash
set -e

# Create asika user if not exists
if ! id -u asika &>/dev/null; then
    dscl . -create /Users/asika
    dscl . -create /Users/asika UserShell /usr/bin/false
    dscl . -create /Users/asika UniqueID 501
    dscl . -create /Users/asika PrimaryGroupID 20
    dscl . -create /Users/asika NFSHomeDirectory /var/lib/asika
fi

# Create directories
mkdir -p /var/lib/asika /var/log/asika
chown -R asika:staff /var/lib/asika /var/log/asika

# Load LaunchDaemon
if launchctl list com.asika.daemon &>/dev/null; then
    launchctl unload /Library/LaunchDaemons/com.asika.daemon.plist 2>/dev/null || true
fi
launchctl load /Library/LaunchDaemons/com.asika.daemon.plist 2>/dev/null || true
POSTINSTALL
chmod +x "$SCRIPTS_DIR/postinstall"

# Build pkg
mkdir -p dist
pkgbuild \
    --root "$ROOT_DIR" \
    --identifier com.asika.daemon \
    --version "$VERSION" \
    --install-location / \
    --scripts "$SCRIPTS_DIR" \
    "dist/asika-${VERSION}-${ARCH}.pkg"

rm -rf "$ROOT_DIR" "$SCRIPTS_DIR"

echo "PKG installer created:"
ls -lh dist/*.pkg