# Builder Repository Integration Guide

This guide explains how builder repositories trigger the central RPM signing and publishing workflows using GitHub Actions `workflow_dispatch`.

## Overview

Builder repositories produce unsigned RPM packages and trigger workflows in the central repository via `workflow_dispatch`. The central repository:

1. Downloads the artifact from the builder repository
2. Signs the RPM with a trusted GPG key
3. Publishes it to the appropriate location on GitHub Pages
4. Updates repository metadata and HTML indexes

**No secrets required in builder repositories** - all GPG signing operations are handled centrally.

## How It Works

```
┌─────────────────────────────────────────┐
│        Builder Repository               │
│                                         │
│  1. Build RPM                           │
│  2. Upload as artifact                  │
│  3. Trigger workflow_dispatch ────────┐ │
└─────────────────────────────────────────┘ │
                                            │
                                            ▼
┌─────────────────────────────────────────────────────┐
│        Central Repository (rpm-repo)                │
│                                                     │
│  4. Download artifact from builder repo            │
│  5. Sign RPM with GPG key                          │
│  6. Publish to gh-pages                            │
│  7. Update metadata and HTML indexes               │
└─────────────────────────────────────────────────────┘
```

## Triggering the Workflow

Add this step to your builder workflow after uploading the RPM artifact:

```yaml
- name: Trigger signing and publishing
  env:
    GH_TOKEN: ${{ github.token }}
  run: |
    gh workflow run sign-and-publish.yml \
      --repo abirkel/rpm-repo \
      --field builder_repo=${{ github.repository }} \
      --field run_id=${{ github.run_id }} \
      --field artifact_name=mypackage-rpm \
      --field distro=fedora \
      --field release=43 \
      --field arch=x86_64 \
      --field build_type=stable
```

## Workflow Parameters

### Required Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `builder_repo` | string | Owner/repo of the builder repository | `myuser/myapp` |
| `run_id` | string | GitHub Actions run ID containing the artifact | `${{ github.run_id }}` |
| `artifact_name` | string | Name of the uploaded artifact | `mypackage-rpm` |
| `release` | string | Release version | `43`, `42`, `rawhide` |
| `arch` | string | Architecture | `x86_64`, `aarch64` |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `distro` | string | `fedora` | Distribution name |
| `build_type` | string | `stable` | Build channel: `stable` or `testing` |

### Parameter Details

- **builder_repo**: The full repository name (owner/repo) where the RPM was built. Use `${{ github.repository }}` to automatically use the current repository.

- **run_id**: The GitHub Actions run ID that contains the artifact. Use `${{ github.run_id }}` to automatically use the current run.

- **artifact_name**: Must match the name used in `actions/upload-artifact`. The artifact should contain one or more RPM files.

- **distro**: Distribution name (e.g., `fedora`, `rhel`). This determines the top-level directory in the repository structure.

- **release**: Release version as a string. Common values:
  - `43`, `42`, `41` for Fedora releases
  - `rawhide` for Fedora development branch
  - `9`, `8` for RHEL/CentOS releases

- **arch**: Target architecture. Common values:
  - `x86_64` (64-bit Intel/AMD)
  - `aarch64` (64-bit ARM)
  - `noarch` (architecture-independent)

- **build_type**: Determines the repository channel:
  - `stable`: Production-ready packages (enabled by default in .repo files)
  - `testing`: Pre-release packages for testing (disabled by default)

## Complete Example Workflow

Here's a complete example for a builder repository at `.github/workflows/build-and-publish.yml`:

```yaml
name: Build and Publish RPM

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up RPM build environment
        run: |
          sudo dnf install -y rpm-build rpmdevtools
          rpmdev-setuptree
      
      - name: Build RPM
        run: |
          rpmbuild -ba mypackage.spec
      
      - name: Upload RPM artifact
        uses: actions/upload-artifact@v4
        with:
          name: mypackage-rpm
          path: ~/rpmbuild/RPMS/x86_64/*.rpm
          retention-days: 5
      
      - name: Trigger signing and publishing
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh workflow run sign-and-publish.yml \
            --repo abirkel/rpm-repo \
            --field builder_repo=${{ github.repository }} \
            --field run_id=${{ github.run_id }} \
            --field artifact_name=mypackage-rpm \
            --field distro=fedora \
            --field release=43 \
            --field arch=x86_64 \
            --field build_type=stable
```

## Publishing to Multiple Distributions

To publish the same RPM to multiple distributions or releases, trigger the workflow multiple times with different parameters:

```yaml
- name: Publish to Fedora 43
  env:
    GH_TOKEN: ${{ github.token }}
  run: |
    gh workflow run sign-and-publish.yml \
      --repo abirkel/rpm-repo \
      --field builder_repo=${{ github.repository }} \
      --field run_id=${{ github.run_id }} \
      --field artifact_name=mypackage-rpm \
      --field distro=fedora \
      --field release=43 \
      --field arch=x86_64 \
      --field build_type=stable

- name: Publish to Fedora 42
  env:
    GH_TOKEN: ${{ github.token }}
  run: |
    gh workflow run sign-and-publish.yml \
      --repo abirkel/rpm-repo \
      --field builder_repo=${{ github.repository }} \
      --field run_id=${{ github.run_id }} \
      --field artifact_name=mypackage-rpm \
      --field distro=fedora \
      --field release=42 \
      --field arch=x86_64 \
      --field build_type=stable

- name: Publish to Fedora Rawhide (testing)
  env:
    GH_TOKEN: ${{ github.token }}
  run: |
    gh workflow run sign-and-publish.yml \
      --repo abirkel/rpm-repo \
      --field builder_repo=${{ github.repository }} \
      --field run_id=${{ github.run_id }} \
      --field artifact_name=mypackage-rpm \
      --field distro=fedora \
      --field release=rawhide \
      --field arch=x86_64 \
      --field build_type=testing
```

## Publishing to Both Stable and Testing

You can publish the same package to both stable and testing channels:

```yaml
- name: Publish to stable
  env:
    GH_TOKEN: ${{ github.token }}
  run: |
    gh workflow run sign-and-publish.yml \
      --repo abirkel/rpm-repo \
      --field builder_repo=${{ github.repository }} \
      --field run_id=${{ github.run_id }} \
      --field artifact_name=mypackage-rpm \
      --field distro=fedora \
      --field release=43 \
      --field arch=x86_64 \
      --field build_type=stable

- name: Publish to testing
  env:
    GH_TOKEN: ${{ github.token }}
  run: |
    gh workflow run sign-and-publish.yml \
      --repo abirkel/rpm-repo \
      --field builder_repo=${{ github.repository }} \
      --field run_id=${{ github.run_id }} \
      --field artifact_name=mypackage-rpm \
      --field distro=fedora \
      --field release=43 \
      --field arch=x86_64 \
      --field build_type=testing
```

## Multi-Architecture Builds

For packages built for multiple architectures, upload separate artifacts and trigger the workflow for each:

```yaml
jobs:
  build-x86_64:
    runs-on: ubuntu-latest
    steps:
      - name: Build x86_64 RPM
        run: rpmbuild -ba --target x86_64 mypackage.spec
      
      - name: Upload x86_64 artifact
        uses: actions/upload-artifact@v4
        with:
          name: mypackage-rpm-x86_64
          path: ~/rpmbuild/RPMS/x86_64/*.rpm
      
      - name: Publish x86_64
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh workflow run sign-and-publish.yml \
            --repo abirkel/rpm-repo \
            --field builder_repo=${{ github.repository }} \
            --field run_id=${{ github.run_id }} \
            --field artifact_name=mypackage-rpm-x86_64 \
            --field release=43 \
            --field arch=x86_64

  build-aarch64:
    runs-on: ubuntu-latest
    steps:
      - name: Build aarch64 RPM
        run: rpmbuild -ba --target aarch64 mypackage.spec
      
      - name: Upload aarch64 artifact
        uses: actions/upload-artifact@v4
        with:
          name: mypackage-rpm-aarch64
          path: ~/rpmbuild/RPMS/aarch64/*.rpm
      
      - name: Publish aarch64
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh workflow run sign-and-publish.yml \
            --repo abirkel/rpm-repo \
            --field builder_repo=${{ github.repository }} \
            --field run_id=${{ github.run_id }} \
            --field artifact_name=mypackage-rpm-aarch64 \
            --field release=43 \
            --field arch=aarch64
```

## Workflow Execution

The sign-and-publish workflow uses a concurrency queue to ensure sequential execution:

- Multiple workflow triggers are queued automatically
- Each workflow processes one RPM at a time
- No concurrent modifications to the gh-pages branch
- Each workflow operates on the latest repository state

You can monitor workflow execution in the Actions tab of the central repository.

## Security Model

- **Builder repositories**: No secrets required, only need permission to trigger workflows
- **Central repository**: Stores GPG private key and passphrase in GitHub Secrets
- **Artifact access**: Central repository downloads artifacts using GitHub CLI with appropriate permissions
- **Signing**: All signing operations occur in the central repository's ephemeral runners

## Permissions Required

Builder repositories need:
- `actions: read` permission to allow the central repository to download artifacts
- `contents: read` permission (default for public repositories)

The central repository needs:
- `contents: write` permission to push to gh-pages branch
- `actions: read` permission to download artifacts from builder repositories

## Troubleshooting

### Artifact Not Found

**Error**: `Failed to download artifact: artifact not found`

**Solution**: Ensure the artifact name matches exactly between upload and workflow_dispatch:

```yaml
# Upload step
- uses: actions/upload-artifact@v4
  with:
    name: mypackage-rpm  # Must match

# Trigger step
--field artifact_name=mypackage-rpm  # Must match
```

### Workflow Not Triggering

**Error**: Workflow doesn't start after triggering

**Solution**: 
1. Verify the central repository has the `sign-and-publish.yml` workflow
2. Check that you're using the correct repository name in `--repo`
3. Ensure your GitHub token has permission to trigger workflows

### Permission Denied

**Error**: `Resource not accessible by integration`

**Solution**: 
1. Check the central repository's Settings → Actions → General
2. Ensure "Allow all actions and reusable workflows" is enabled
3. Verify workflow permissions are set to "Read and write permissions"

### Package Not Appearing

**Error**: Workflow succeeds but package isn't in repository

**Solution**:
1. Check the workflow logs in the central repository's Actions tab
2. Verify the gh-pages branch was updated
3. Wait a few minutes for GitHub Pages to deploy
4. Clear your local dnf cache: `sudo dnf clean all`

### GPG Signature Verification Failed

**Error**: `rpm --checksig` fails in the workflow

**Solution**:
1. Verify GPG secrets are correctly configured in the central repository
2. Check that `GPG_PRIVATE_KEY` is base64-encoded
3. Ensure `GPG_PRIVATE_KEY_PASS` matches the key's passphrase

### Multiple RPM Files in Artifact

**Behavior**: If the artifact contains multiple RPM files, the workflow processes the first one found.

**Solution**: Upload separate artifacts for each RPM or ensure only one RPM is in the artifact directory.

## Additional Resources

- See [examples/builder-workflow.yml](examples/builder-workflow.yml) for a complete, copy-paste-ready example
- See the main [README.md](README.md) for end-user installation instructions
- See `scripts/` directory for repository setup and maintenance scripts
