# Contributing to Asika Pack

Thank you for helping improve Asika's packaging and release system!

## How to Contribute

- Fix or improve packaging scripts in `scripts/`
- Update Debian packaging files in `debian/`
- Add or modify service templates in `templates/`
- Improve the GitHub Composite Action in `action.yml`
- Update documentation

## Development Environment

Depending on what you're working on, you may need:

- **Bash scripts**: Any Unix-like system with Bash 3.2+
- **Debian packages**: A Debian/Ubuntu system with `debhelper`, `dpkg-dev`
- **Docker images**: Docker with `buildx` support
- **NSIS installers**: Windows with NSIS (or Wine on Linux)
- **DMG packages**: macOS with Xcode command line tools

## Coding Standards

### Shell Scripts
- Use `#!/bin/bash` shebang
- Always use `set -e` for fail-fast behavior
- Quote all variable expansions: `"$VAR"`, not `$VAR`
- Check for required tools before using them:
  ```bash
  if ! command -v makensis &> /dev/null; then
      echo "Error: makensis not found" >&2
      exit 1
  fi
  ```
- Use `local` for function-scoped variables

### Debian Packaging
- Follow standard Debian conventions
- Test changes with: `dpkg-buildpackage -us -uc`
- Keep `debian/changelog` updated for version tracking
- Use `dh` sequencer in `debian/rules` when possible

### Templates
- Use `@@VARIABLE@@` placeholders for configurable values
- Document all placeholders in comments
- Keep paths consistent (use `/usr` in templates, not `/usr/local`)

### Cross-Platform Scripts
- Platform-specific scripts should check `uname -s` and exit gracefully on unsupported platforms
- Avoid GNU-specific features in scripts that run on macOS
- Test on target platforms when possible

## Testing

Before submitting your changes, do a quick sanity check:

```bash
# Check shell script syntax
bash -n scripts/package-deb.sh

# Format shell scripts with shfmt
shfmt -w -i 4 -ci scripts/*.sh

# Lint shell scripts with shellcheck
shellcheck scripts/*.sh

# Test Debian package build (requires Debian/Ubuntu)
cd /path/to/pack && dpkg-buildpackage -us -uc

# Validate YAML syntax (for action.yml)
python3 -c "import yaml; yaml.safe_load(open('action.yml'))"
```

### CI Checks

The CI pipeline runs these checks automatically. To run them locally:

```bash
# Install tools (if not already installed)
# shfmt: go install mvdan.cc/sh/v3/cmd/shfmt@latest
# shellcheck: https://github.com/koalaman/shellcheck#installing

# Check all scripts
for f in scripts/*.sh; do
    shfmt -d -i 4 -ci "$f"
    shellcheck "$f"
done
```

## Pull Request Process

1. Create a new branch from `main`
2. Make your changes
3. Write a concise commit message (under 50 characters for the title)
4. Open a pull request with a brief description:
   - What you changed
   - Why you changed it
   - How to test it
5. Link to any related issues

## Questions?

Feel free to open an issue for discussion before starting work on major changes.
