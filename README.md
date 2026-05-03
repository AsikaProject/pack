# Asika Pack - Release Packaging

This repository contains the packaging scripts and configuration for building and releasing [Asika](https://github.com/AsikaProject/asika) across multiple platforms.

## Overview

This repo is designed as a **Composite Action** for GitHub Actions. It provides modular, reusable packaging logic that the main `asika` repo calls during its release workflow.

## Repository Structure

```
pack/
├── action.yml              # GitHub Composite Action entry point
├── Dockerfile              # Multi-stage Docker build (amd64/arm64)
├── debian/                 # Standard Debian packaging (source + asika + asikad)
│   ├── control
│   ├── rules
│   ├── changelog
│   ├── compat
│   ├── copyright
│   ├── asika.install
│   ├── asikad.install
│   ├── asikad.postinst
│   ├── asikad.prerm
│   └── source/format
├── scripts/                # Packaging scripts
│   ├── build-binaries.sh   # Cross-compile for 9 platforms
│   ├── package-deb.sh     # Build .deb packages
│   ├── package-dmg.sh     # Build macOS .dmg images
│   ├── package-nsis.sh    # Build Windows .exe installers
│   └── package-docker.sh  # Build & push Docker images
└── templates/              # Platform-specific templates
    ├── service/            # Service files (systemd, openrc, etc.)
    │   ├── asikad.service
    │   ├── asikad.openrc
    │   ├── com.asika.daemon.plist
    │   ├── asikad.desktop
    │   └── asikad.command
    └── nsis/               # NSIS installer script
        └── install.nsi
```

## Supported Platforms

### Binaries (Go cross-compilation)
- **Linux**: amd64, arm64, armhf, riscv64, loong64
- **macOS**: amd64, arm64
- **Windows**: amd64, arm64

### Package Formats
| Platform | Format | Architectures |
|----------|--------|---------------|
| Linux    | `.deb` | amd64, arm64, armhf, riscv64, loong64 |
| macOS    | `.dmg` | amd64, arm64 |
| Windows  | `.exe` (NSIS) | amd64, arm64 |
| Docker   | Image (ghcr.io) | amd64, arm64 |

## Versioning

Asika uses date-based versioning: `YYYYMMDD[SUFFIX]`
- `20260503` - Stable release
- `20260503DEV` - Development/Beta version
- `20260503HF` - Hot fix
- `20260503CVE` - Security update
- `20260503DEP` - Dependency update

The NSIS installer automatically converts this to a 4-part version (e.g., `2026` → `2.0.2.6`).

## Usage

This repo is designed to be called as a Composite Action from the `asika` repo's release workflow:

```yaml
- name: Checkout pack
  uses: actions/checkout@v4
  with:
    repository: AsikaProject/pack
    path: pack
    token: ${{ secrets.GITHUB_TOKEN }}

- name: Build binaries
  run: bash pack/scripts/build-binaries.sh
  env:
    GO_VERSION: '1.25.0'
    TAG_NAME: ${{ github.ref_name }}
```

## Scripts

### `build-binaries.sh`
Cross-compiles `asika` (CLI) and `asikad` (daemon) for all supported platforms.

**Environment variables:**
- `GO_VERSION` - Go version (default: 1.25.0)
- `BINARIES` - Comma-separated list of binaries (default: asika,asikad)
- `TAG_NAME` - Release tag (for binary naming)

### `package-deb.sh`
Builds Debian packages using the standard `debian/` directory. Replaces `/usr/local` with `/usr` in service templates.

**Environment variables:**
- `TAG_NAME` - Release version

### `package-dmg.sh`
Creates macOS `.dmg` installer. **Requires macOS runner.**

### `package-nsis.sh`
Creates Windows `.exe` installer using NSIS. **Requires Windows runner.**

### `package-docker.sh`
Builds and pushes multi-architecture Docker images to ghcr.io. Uses `buildx` for cross-platform builds.

**Environment variables:**
- `DOCKER_REGISTRY` - Registry URL (default: ghcr.io)
- `DOCKER_IMAGE_NAME` - Image name (default: asika)
- `GITHUB_TOKEN` - GitHub token for registry login

## Debian Packaging

The `debian/` directory follows standard Debian packaging conventions:
- **Source package**: `asika`
- **Binary packages**: `asika` (CLI tools) and `asikad` (daemon service)
- `asikad` depends on `asika` (same version)
- Post-install script creates `asika` user and directories
- Pre-remove script stops the service

**Note**: The service files install to `/usr/local` by default. The `package-deb.sh` script replaces these with `/usr` before building.

## Docker

The `Dockerfile` uses a multi-stage build:
1. **Builder stage**: Compiles `asika` and `asikad` using Golang 1.25.0
2. **Runtime stage**: Minimal Alpine Linux with only the binaries

**Exposed port**: 8080 (adjust as needed)
**Default command**: `asikad serve`

## License

BSD-3-Clause - See `LICENSE` in the `asika` repository.
