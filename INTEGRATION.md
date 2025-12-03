# Builder Repository Integration

This guide explains how to integrate your builder repositories with the central RPM signing and publishing repository.

## Quick Start

1. Build your RPM in your builder repository
2. Upload it as a GitHub Actions artifact
3. Call the reusable workflow from this repository
4. The RPM will be automatically signed and published

## Example Workflow

Add this to your builder repository at `.github/workflows/build-and-publish.yml`:

```yaml
name: Build and Publish RPM

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build RPM
        run: |
          # Your RPM build commands here
          rpmbuild -ba mypackage.spec
          
      - name: Upload RPM artifact
        uses: actions/upload-artifact@v4
        with:
          name: mypackage-rpm
          path: ~/rpmbuild/RPMS/x86_64/*.rpm

  publish:
    needs: build
    uses: <your-user>/rpm-repo/.github/workflows/publish-rpm.yml@main
    with:
      rpm_artifact_name: mypackage-rpm
      distro: fedora
      release: "43"
      arch: x86_64
    secrets: inherit
```

## Workflow Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `rpm_artifact_name` | string | Yes | - | Name of the artifact containing the RPM |
| `distro` | string | No | `fedora` | Distribution name |
| `release` | string | Yes | - | Release version (43, 42, rawhide) |
| `arch` | string | Yes | - | Architecture (x86_64, aarch64) |

## Publishing to Multiple Distributions

To publish the same RPM to multiple distributions, add multiple publish jobs:

```yaml
  publish-fedora-43:
    needs: build
    uses: <your-user>/rpm-repo/.github/workflows/publish-rpm.yml@main
    with:
      rpm_artifact_name: mypackage-rpm
      distro: fedora
      release: "43"
      arch: x86_64
    secrets: inherit

  publish-fedora-42:
    needs: build
    uses: <your-user>/rpm-repo/.github/workflows/publish-rpm.yml@main
    with:
      rpm_artifact_name: mypackage-rpm
      distro: fedora
      release: "42"
      arch: x86_64
    secrets: inherit
```

## No Secrets Required

Builder repositories do NOT need to manage GPG keys or any secrets. All signing operations are handled by the central repository using its own secrets.

## Complete Example

See [examples/builder-workflow.yml](examples/builder-workflow.yml) for a complete, copy-paste-ready workflow with detailed comments.

## Troubleshooting

### Artifact Not Found

Ensure the artifact name matches between upload and publish:
```yaml
# In build job
- name: Upload RPM artifact
  uses: actions/upload-artifact@v4
  with:
    name: mypackage-rpm  # Must match

# In publish job
with:
  rpm_artifact_name: mypackage-rpm  # Must match
```

### Workflow Permission Denied

Ensure your builder repository has permission to call workflows from the central repository. Check the central repository's Settings → Actions → General → "Workflow permissions".

### Package Not Appearing

Check:
- Workflow completed successfully (check Actions tab)
- The `gh-pages` branch was updated in the central repository
- Clear your local dnf cache: `sudo dnf clean all`

### GPG Signature Error

Import the public key:
```bash
sudo rpm --import https://<your-user>.github.io/rpm-repo/repo/public.gpg
```
