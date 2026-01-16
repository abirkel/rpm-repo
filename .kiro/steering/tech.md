# Tech Stack & Build System

## Core Technologies

- **GitHub Actions** - CI/CD automation and workflow orchestration
- **Bash** - Shell scripting for setup and maintenance tasks
- **GPG** - Cryptographic signing of RPM packages
- **RPM Tools** - `rpmsign`, `createrepo_c`, `rpm` for package management
- **GitHub Pages** - Static hosting for the public repository
- **GitHub CLI (gh)** - Command-line interface for GitHub operations

## Key Tools & Commands

### RPM Signing
```bash
rpmsign --addsign <rpm-file>  # Sign an RPM package
rpm --checksig <rpm-file>     # Verify RPM signature
```

### Repository Metadata
```bash
createrepo_c <directory>      # Generate repository metadata
xmllint <repomd.xml>          # Validate XML metadata
```

### GPG Operations
```bash
gpg --generate-key            # Generate GPG key pair
gpg --export-secret-key       # Export private key
gpg --import                  # Import GPG key
```

### GitHub Operations
```bash
gh workflow run <workflow>    # Trigger workflow_dispatch
gh secret set <name>         # Set repository secrets
gh artifact download         # Download workflow artifacts
```

## Project Structure

- `.github/workflows/` - GitHub Actions workflow definitions
- `.github/prune-config.yml` - Configuration for package pruning
- `scripts/` - Setup and maintenance scripts
- `repo/` - Repository configuration files (.repo files, public GPG key)
- `examples/` - Example workflows for builder repositories

## Common Commands

### Setup
```bash
bash scripts/setup-repository.sh      # Interactive setup wizard
bash scripts/setup-gpg.sh             # Generate GPG keys and set secrets
bash scripts/init-repo-files.sh       # Initialize repository files
```

### Maintenance
```bash
bash scripts/setup-permissions.sh     # Configure repository permissions
```

## Workflow Triggers

- **sign-and-publish.yml** - Triggered by builder repos via `workflow_dispatch`
- **delete-package.yml** - Manual workflow for removing packages
- **prune-packages.yml** - Scheduled weekly, or manual via `workflow_dispatch`

## Configuration Files

- `.repo` files - DNF/YUM repository configuration (abirkel-stable.repo, abirkel-testing.repo)
- `public.gpg` - Public GPG key for signature verification
- `prune-config.yml` - Package retention policies (max_branches, max_versions)

## Dependencies

- GitHub CLI (gh) - Required for setup scripts
- GPG - Required for key generation and signing
- RPM build tools - Required for signing and metadata generation
- createrepo_c - Required for repository metadata
- xmllint - Required for XML validation

## Deployment

All workflows run on GitHub Actions runners. The repository is published to GitHub Pages, which serves the RPM packages and metadata publicly.
