# AGENTS.md - Asika Pack

## Purpose
Packaging repo for [Asika](https://github.com/AsikaProject/asika). Provides GitHub Composite Action (`action.yml`) called by the main repo's release workflow. **No Go source code here** - scripts expect to run from the main `asika` repo context where `./cmd/asika` and `./cmd/asikad` exist.

## Commands
```bash
# Lint shell scripts (requires shellcheck, shfmt)
for f in scripts/*.sh; do shellcheck "$f"; done

# Check syntax without running
bash -n scripts/package-deb.sh

# Debian package test (requires Debian/Ubuntu)
dpkg-buildpackage -us -uc
```

## Architecture
- `action.yml` - Composite Action entry point, dispatches to platform-specific scripts
- `scripts/` - Packaging scripts (Bash, all use `set -e`)
  - `build-binaries.sh` - Cross-compile for 9 platforms (Linux/macOS/Windows, amd64/arm64/armhf/riscv64/loong64)
  - `package-deb.sh` - Debian packages (uses Docker + `debian/` dir)
  - `package-dmg.sh` - macOS .dmg (requires macOS runner)
  - `package-nsis.sh` - Windows .exe installer (requires Windows runner `windows-latest`, NSIS)
  - `templates/nsis/` - Installer resources:
    - `install.nsi` - Modern UI with components, multi-language (EN/CN/JP), firewall rules
    - `asika.ico` - Installer/uninstaller icon (replace with branded icon)
    - `header.bmp` - Page header image (150x57 px, replace with custom)
    - `welcome.bmp` - Welcome/Finish page image (164x314 px, replace with custom)
  - `package-pkg.sh` - macOS .pkg installer (requires macOS runner)
  - `package-docker.sh` - Multi-arch Docker images via buildx
- `debian/` - Standard Debian packaging (source package: `asika`, binary: `asika` + `asikad`)
- `templates/` - Service files and NSIS script with `@@VARIABLE@@` placeholders

## Key Conventions
- **Version format**: Date-based `YYYYMMDD[SUFFIX]` (e.g., `20260503DEV`). NSIS converts to 4-part: `2026` → `2.0.2.6`
- **Service templates**: Use `/usr` not `/usr/local`; `package-deb.sh` does `sed` replacement before build
- **Dockerfile**: Multi-stage build expects Go source in build context (`./cmd/asika`, `./cmd/asikad`, `go.mod`)
- **Environment variables**: `GO_VERSION` (default 1.25.0), `TAG_NAME`, `BINARIES` (comma-separated), `DOCKER_REGISTRY` (default ghcr.io)

## Platform Quirks
- DMG/PKG packaging: **must run on macOS runner** (`uname -s` check in scripts)
- NSIS packaging: **must run on Windows runner** (detects MINGW/MSYS/CYGWIN)
- Docker builds: Requires `buildx` with QEMU for multi-arch (amd64/arm64 only for ghcr.io)
- Debian builds: Run inside `debian:sid` Docker container via `package-deb.sh`
