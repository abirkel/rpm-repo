# RPM Repository Automation - Product Overview

## What This Project Does

This is a centralized RPM package repository that automates GPG signing and publishing for Linux packages. It acts as a hub between builder repositories (which produce unsigned RPMs) and end users (who install signed packages).

## Architecture

**Three-tier workflow:**
1. **Builder repositories** - Build unsigned RPM packages and trigger workflows in this central repo
2. **Central repository** (this project) - Downloads artifacts, signs them with GPG, and publishes to GitHub Pages
3. **End users** - Install packages from the public repository with verified GPG signatures

## Key Features

- Automated GPG signing of RPM packages
- Multi-distribution support (Fedora, RHEL, etc.)
- Multi-architecture support (x86_64, aarch64, etc.)
- Stable and testing package channels
- Automatic repository metadata generation
- GitHub Pages hosting for public access
- Package pruning to manage repository size
- Package deletion capabilities

## Security Model

- Builder repositories require **no secrets** - only permission to trigger workflows
- All GPG signing happens in the central repository's secure environment
- Public GPG key is distributed with the repository
- Packages are verified before publishing

## Integration Pattern

Builder repositories trigger the central repository's workflows using GitHub Actions `workflow_dispatch`. This allows decoupled, secure publishing without sharing secrets across repositories.
