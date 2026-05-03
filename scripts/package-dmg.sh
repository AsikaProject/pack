#!/bin/bash
set -e

TAG_NAME="${TAG_NAME:-v0.0.0}"
VERSION=${TAG_NAME#v}

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Error: DMG packaging requires macOS runner"
    exit 1
fi

echo "Building DMG for version ${VERSION}..."

# Create .app directory structure
APP_NAME="Asika"
APP_DIR="${APP_NAME}.app/Contents"

rm -rf "${APP_NAME}.app"
mkdir -p "${APP_DIR}/MacOS"
mkdir -p "${APP_DIR}/Resources"

# Copy binary
if [ -f "bin/asikad-darwin-amd64" ]; then
    cp "bin/asikad-darwin-amd64" "${APP_DIR}/MacOS/asikad"
    chmod +x "${APP_DIR}/MacOS/asikad"
    ARCH="amd64"
elif [ -f "bin/asikad-darwin-arm64" ]; then
    cp "bin/asikad-darwin-arm64" "${APP_DIR}/MacOS/asikad"
    chmod +x "${APP_DIR}/MacOS/asikad"
    ARCH="arm64"
else
    echo "Error: No asikad binary found for macOS"
    exit 1
fi

# Create Info.plist
cat > "${APP_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>asikad</string>
    <key>CFBundleIdentifier</key>
    <string>com.asika.daemon</string>
    <key>CFBundleName</key>
    <string>Asika</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.10</string>
</dict>
</plist>
EOF

# Create DMG
mkdir -p dist
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${APP_NAME}.app" \
    -ov \
    -format UDZO \
    "dist/asika-${VERSION}-${ARCH}.dmg"

echo "DMG created: dist/asika-${VERSION}-${ARCH}.dmg"
ls -lh dist/
