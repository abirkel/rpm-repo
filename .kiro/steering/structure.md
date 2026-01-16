# Project Structure

## Directory Layout

```
rpm-repo/
├── .github/
│   ├── workflows/
│   │   ├── sign-and-publish.yml      # Main workflow: download, sign, publish RPMs
│   │   ├── delete-package.yml        # Delete packages from repository
│   │   └── prune-packages.yml        # Scheduled pruning of old packages
│   └── prune-config.yml              # Configuration for pruning (max_branches, max_versions)
│
├── scripts/
│   ├── setup-repository.sh           # Interactive setup wizard
│   ├── setup-gpg.sh                  # Generate GPG keys and GitHub secrets
│   ├── setup-permissions.sh          # Configure repository permissions
│   └── init-repo-files.sh            # Initialize .repo files on gh-pages
│
├── repo/
│   ├── public.gpg                    # Public GPG key (committed to main)
│   ├── abirkel-stable.repo           # DNF/YUM config for stable packages
│   └── abirkel-testing.repo          # DNF/YUM config for testing packages
│
├── examples/
│   └── builder-workflow.yml          # Example workflow for builder repositories
│
├── .kiro/
│   └── specs/                        # Feature specifications and tasks
│
├── README.md                         # User-facing documentation
├── INTEGRATION.md                    # Builder repository integration guide
└── gh-pages-workflow.md              # Critical rules for gh-pages operations
```

## gh-pages Branch Structure

The `gh-pages` branch contains the published repository and is served via GitHub Pages:

```
gh-pages/
├── public.gpg                        # Public GPG key
├── abirkel-stable.repo               # Stable repository config
├── abirkel-testing.repo              # Testing repository config
├── index.html                        # Directory listing (auto-generated)
│
└── fedora/
    ├── 43/
    │   ├── stable/
    │   │   ├── repodata/
    │   │   │   ├── repomd.xml
    │   │   │   ├── primary.xml.gz
    │   │   │   └── ...
    │   │   ├── x86_64/
    │   │   │   └── mypackage-1.0-1.fc43.x86_64.rpm
    │   │   └── noarch/
    │   │       └── mypackage-common-1.0-1.fc43.noarch.rpm
    │   └── testing/
    │       ├── repodata/
    │       ├── x86_64/
    │       │   └── mypackage-2.0-1.fc43.x86_64.rpm
    │       └── noarch/
    └── rawhide/
        ├── stable/
        │   ├── repodata/
        │   ├── x86_64/
        │   └── aarch64/
        └── testing/
            ├── repodata/
            ├── x86_64/
            └── aarch64/
```

## Key Files

### Workflows
- **sign-and-publish.yml** - Core workflow that handles artifact download, GPG signing, publishing, and metadata generation
- **delete-package.yml** - Removes specific packages or all versions of a package
- **prune-packages.yml** - Automatically removes old packages based on retention policy

### Configuration
- **prune-config.yml** - Defines `max_branches` (keep newest N distributions) and `max_versions` (keep newest N versions per build_type)
- **.repo files** - DNF/YUM repository configuration with GPG key URL and repository URLs

### Scripts
- **setup-repository.sh** - Main entry point for initial setup
- **setup-gpg.sh** - Generates GPG keys and configures GitHub secrets
- **init-repo-files.sh** - Deploys .repo files and public key to gh-pages
- **setup-permissions.sh** - Configures branch protection and workflow permissions

## Naming Conventions

### Repository Structure
- **Distribution**: `fedora`, `rhel`, `centos`, etc.
- **Release**: `43`, `42`, `rawhide` (Fedora), `9`, `8` (RHEL)
- **Architecture**: `x86_64`, `aarch64`, `noarch`
- **Build Type**: `stable` (production), `testing` (pre-release)

### File Paths
```
{distro}/{release}/{build_type}/{arch}/{package-name-version-release.arch.rpm}
```

Example:
```
fedora/43/stable/x86_64/myapp-1.2.3-1.fc43.x86_64.rpm
fedora/rawhide/testing/aarch64/myapp-2.0.0-1.fc40.aarch64.rpm
fedora/43/stable/noarch/myapp-common-1.0-1.fc43.noarch.rpm
```

## Important Rules

- **Never switch branches in the main workspace** - Use separate `gh_pages` subfolder for gh-pages operations
- **Preserve .kiro and .vscode folders** - These contain critical project configuration
- **Commit public.gpg to main branch** - The public key is part of the repository
- **Deploy .repo files to gh-pages** - Configuration files are served from GitHub Pages
- **Use orphan gh-pages branch** - Separate history from main branch

## Workflow Data Flow

1. Builder repo uploads RPM artifact
2. Builder repo triggers `sign-and-publish.yml` with parameters
3. Central repo downloads artifact from builder
4. Central repo signs RPM with GPG key
5. Central repo moves RPM to `{distro}/{release}/{build_type}/{arch}/`
6. Central repo generates/updates repository metadata with `createrepo_c` at `{distro}/{release}/{build_type}/` level
7. Central repo generates HTML directory listings
8. Central repo commits and pushes to gh-pages
9. GitHub Pages serves the updated repository

## Maintenance Tasks

- **Pruning** - Runs weekly to remove old packages (configurable retention)
- **Deletion** - Manual workflow to remove specific packages
- **GPG Key Rotation** - Regenerate keys and update secrets (manual process)
- **Repository Cleanup** - Remove orphaned metadata or corrupted files
