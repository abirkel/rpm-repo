# Design Document

## Overview

The RPM Repository Automation system is a GitHub Actions-based solution for centralized RPM package signing and publishing. The system operates entirely within GitHub's infrastructure, using GitHub Pages to host the repository and GitHub Actions workflows to automate all operations.

The architecture follows a hub-and-spoke model where builder repositories (spokes) trigger workflows in this central repository (hub) via workflow_dispatch. The central repository handles all security-sensitive operations (GPG signing) and maintains the authoritative package repository on the gh-pages branch.

Key design principles:
- **Security isolation**: GPG keys never leave the central repository
- **Incremental updates**: Repository metadata is updated incrementally to avoid downloading entire repository
- **Idempotent operations**: Workflows can be safely retried without side effects
- **Queue-based execution**: Concurrent operations are serialized to prevent conflicts
- **Minimal branch switching**: Workflows operate primarily on gh-pages to avoid complexity

## Architecture

### Workflow Execution Model

The system uses GitHub Actions concurrency control to implement a queue for the sign-and-publish workflow:

```yaml
concurrency:
  group: rpm-publish
  cancel-in-progress: false
```

This ensures that:
1. All sign-and-publish operations execute sequentially
2. No concurrent modifications to gh-pages occur
3. Workflows wait in queue rather than failing due to conflicts
4. Each workflow operates on the latest gh-pages state

## Components and Interfaces

### 1. Sign and Publish Workflow

**File**: `.github/workflows/sign-and-publish.yml`

**Trigger**: `workflow_dispatch` from external repositories

**Inputs**:
- `builder_repo` (string, required): Owner/repo of the builder repository
- `run_id` (string, required): GitHub Actions run ID containing the artifact
- `artifact_name` (string, required): Name of the uploaded artifact
- `distro` (string, optional, default: "fedora"): Distribution name
- `release` (string, required): Release version (e.g., "43", "rawhide")
- `arch` (string, required): Architecture (e.g., "x86_64", "aarch64")
- `build_type` (string, optional, default: "stable"): Either "stable" or "testing"

**Secrets Required**:
- `GPG_PRIVATE_KEY`: Base64-encoded GPG private key
- `GPG_PRIVATE_KEY_PASS`: Passphrase for GPG key (can be empty if key has no passphrase)
- `GPG_KEY_ID`: GPG key ID (optional, for verification)

**Outputs**: None (commits to gh-pages branch)

**Responsibilities**:
1. Download artifact from builder repository using `gh run download`
2. Locate RPM file within artifact
3. Set up GPG environment for signing
4. Sign RPM using rpmsign with .rpmmacros configuration
5. Verify signature using `rpm --checksig`
6. Move signed RPM to target directory
7. Update repository metadata with createrepo_c
8. Generate HTML directory listings
9. Commit and push to gh-pages

### 2. Delete Package Workflow

**File**: `.github/workflows/delete-package.yml` (adapted from `.ref/delete-package.yml`)

**Trigger**: `workflow_dispatch` (manual)

**Inputs**:
- `package_filename` (string, optional): Full RPM filename (e.g., mypackage-1.2.3-1.fc43.x86_64.rpm)
- `package_name` (string, optional): Package name (e.g., mypackage) - required if package_filename not provided
- `distro` (string, optional): Distribution name (e.g., fedora) - required if package_filename not provided
- `release` (string, optional): Release version (e.g., 43) - required if package_filename not provided
- `arch` (string, optional): Architecture (e.g., x86_64) - required if package_filename not provided
- `build_type` (choice, optional, default: "stable"): stable, testing, or search_all
- `dry_run` (boolean, optional, default: false): Preview mode without making changes

**Outputs**: None (commits to gh-pages branch or displays preview)

**Responsibilities**:
1. Validate input combinations
2. Locate package(s) to delete
3. Delete RPM file(s) or display what would be deleted
4. Update repository metadata
5. Clean up empty directories
6. Generate HTML directory listings
7. Commit and push to gh-pages

### 3. Prune Packages Workflow

**File**: `.github/workflows/prune-packages.yml` (adapted from `.ref/prune-packages.yml`)

**Trigger**: 
- `schedule`: Weekly cron (Sundays at 2 AM UTC)
- `workflow_dispatch`: Manual trigger

**Configuration**: Reads from `.github/prune-config.yml` (copied from `.ref/prune-config.yml`)

**Configuration Format**:
```yaml
max_branches: 2                    # Keep 2 newest releases per distribution
max_versions:
  stable: 5                        # Keep 5 newest stable versions per package
  testing: 3                       # Keep 3 newest testing versions per package
```

**Outputs**: None (commits to gh-pages branch)

**Responsibilities**:
1. Sparse checkout of prune-config.yml from main branch
2. Parse configuration (max_branches, max_versions)
3. Prune old distribution releases
4. Prune old package versions within remaining releases
5. Update repository metadata for affected directories
6. Generate HTML directory listings
7. Commit and push to gh-pages

## Data Models

### Directory Structure Model

```
gh-pages/
├── fedora/
│   ├── {release}/           # e.g., "43", "42", "rawhide"
│   │   └── {arch}/          # e.g., "x86_64", "aarch64"
│   │       ├── stable/
│   │       │   ├── repodata/
│   │       │   │   ├── repomd.xml
│   │       │   │   ├── *-primary.xml.gz
│   │       │   │   ├── *-filelists.xml.gz
│   │       │   │   └── *-other.xml.gz
│   │       │   ├── *.rpm
│   │       │   └── index.html
│   │       └── testing/
│   │           ├── repodata/
│   │           ├── *.rpm
│   │           └── index.html
├── public.gpg
├── stable.repo
├── testing.repo
└── index.html
```

### Workflow Dispatch Payload

```json
{
  "builder_repo": "owner/repo-name",
  "run_id": "1234567890",
  "artifact_name": "my-package-rpm",
  "distro": "fedora",
  "release": "43",
  "arch": "x86_64",
  "build_type": "stable"
}
```

### Prune Configuration Model

```yaml
max_branches: integer  # Number of release branches to keep (>= 1)
max_versions:
  stable: integer      # Number of stable versions to keep per package (>= 1)
  testing: integer     # Number of testing versions to keep per package (>= 1)
```

## Error Handling

### Error Categories

1. **Input Validation Errors**
   - Invalid or missing workflow parameters
   - Malformed artifact names or repository references
   - Invalid distribution, release, or architecture values
   - **Handling**: Fail fast with descriptive error message, do not modify repository

2. **Artifact Download Errors**
   - Artifact not found in builder repository
   - Network failures during download
   - Insufficient permissions to access artifact
   - **Handling**: Retry with exponential backoff (up to 3 attempts), then fail with error

3. **GPG Signing Errors**
   - Missing or invalid GPG secrets
   - GPG key import failures
   - Signing operation failures
   - Signature verification failures
   - **Handling**: Clean up GPG environment, fail with error, do not publish unsigned RPM

4. **File System Errors**
   - Unable to create target directories
   - Insufficient disk space
   - Permission denied errors
   - **Handling**: Fail with error, attempt cleanup of partial changes

5. **Repository Metadata Errors**
   - createrepo_c command failures
   - Invalid XML generation
   - Missing metadata files
   - **Handling**: Fail with error, do not commit invalid metadata

6. **Git Operation Errors**
   - Checkout failures
   - Commit failures
   - Push conflicts (after retries)
   - Network failures during push
   - **Handling**: Retry with rebase (up to 3 attempts), rollback uncommitted changes on failure

7. **Configuration Errors**
   - Missing or invalid prune-config.yml
   - Invalid configuration values
   - **Handling**: Use default values with warning, or fail if values are critically invalid

### Error Recovery Strategies

1. **Transient Errors**: Retry with exponential backoff (2s, 4s, 8s)
2. **Permanent Errors**: Fail fast with descriptive error message
3. **Partial State**: Rollback uncommitted changes using `git reset --hard HEAD`
4. **Resource Cleanup**: Always clean up GPG keys and temporary files in `if: always()` steps

## Testing Strategy

### Unit Testing

Unit tests will cover:
- Path construction logic (distro/release/arch/build_type combinations)
- Configuration file parsing (prune-config.yml)
- Version comparison logic (RPM version semantics)
- Placeholder replacement in .repo files
- Error message formatting

### Property-Based Testing

Property-based tests will verify universal properties across many inputs using a property-based testing library. Each property test will:
- Run a minimum of 100 iterations with randomly generated inputs
- Be tagged with a comment referencing the design document property
- Use the format: `# Feature: rpm-repository-automation, Property N: <property text>`

Property tests will cover:
- Artifact download with various valid repository/artifact combinations
- Sign/verify round-trip with various RPM files
- Path construction with all valid parameter combinations
- Overwrite behavior with duplicate filenames
- Metadata generation for directories with varying numbers of RPMs
- HTML content verification across different directory structures
- Branch pruning with various max_branches values
- Version pruning with various max_versions values
- RPM version comparison with complex version strings
- Placeholder replacement with various owner names

### Integration Testing

Integration tests will verify:
- Complete sign-and-publish workflow from trigger to gh-pages commit
- Delete workflow with actual repository structure
- Prune workflow with multiple releases and versions
- Concurrent workflow execution (queue behavior)
- HTML generation with actual directory structures

### Edge Case Testing

Specific edge cases to test:
- Multiple RPM files in single artifact
- Rawhide release preservation during pruning
- Empty directories after package deletion
- Concurrent workflow triggers
- Network failures and retries
- Invalid GPG keys
- Corrupted RPM files
- Malformed metadata XML
