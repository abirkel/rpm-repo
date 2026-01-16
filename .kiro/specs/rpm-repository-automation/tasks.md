# Implementation Plan

- [x] 1. Repository initialization and cleanup
  - Delete all existing workflows and actions
  - Reinitialize git repository with clean history
  - Configure git user from global settings
  - Create initial commit on main branch
  - _Requirements: All_

- [x] 2. Create sign and publish workflow
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5, 11.1, 11.2, 11.3, 11.5_

- [x] 2.1 Create workflow file structure
  - Create `.github/workflows/sign-and-publish.yml`
  - Define workflow_dispatch trigger with all required inputs
  - Configure concurrency group for queue behavior
  - Set required permissions (contents: write, actions: read)
  - _Requirements: 1.1, 11.1, 11.2_

- [x] 2.2 Implement artifact download step
  - Checkout gh-pages branch (create if doesn't exist)
  - Install gh CLI and required tools
  - Download artifact from builder repository using gh CLI
  - Verify artifact directory exists and contains files
  - Locate RPM file within artifact (first .rpm file found)
  - _Requirements: 1.2, 1.3, 1.4, 1.5_

- [x] 2.3 Implement GPG signing step
  - Create ~/.gnupg directory with secure permissions
  - Import GPG private key from base64-encoded secret
  - Extract key ID from imported key
  - Configure GPG for loopback pinentry mode
  - Create ~/.rpmmacros file with signing configuration
  - Write passphrase to secure temporary file
  - Execute rpmsign --addsign command
  - Clean up passphrase file
  - _Requirements: 2.1, 2.2_

- [x] 2.4 Implement signature verification step
  - Run rpm --checksig on signed RPM
  - Parse output to verify signature is valid
  - Check signature matches expected key ID
  - Terminate with error if verification fails
  - _Requirements: 2.3, 2.4_

- [x] 2.5 Implement RPM publishing step
  - Construct target directory path: {distro}/{release}/{arch}/{build_type}/
  - Create target directory structure if it doesn't exist
  - Move signed RPM to target directory
  - Verify RPM was moved successfully
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 2.6 Implement metadata update step
  - Check if repodata directory exists
  - Run createrepo_c with --update flag if metadata exists
  - Run createrepo_c without --update flag if metadata doesn't exist
  - Validate generated repomd.xml is well-formed XML using xmllint
  - Terminate with error if validation fails
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 2.7 Implement HTML index generation step
  - Use jayanta525/github-pages-directory-listing@v4.0.0 action
  - Configure to scan from repository root
  - Verify index.html files are generated
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 2.8 Implement commit and push step
  - Configure git user as github-actions[bot]
  - Stage all changes
  - Check if there are changes to commit
  - Create commit with descriptive message including RPM filename and path
  - Push to gh-pages with retry logic (3 attempts)
  - Attempt rebase on push conflicts
  - Terminate with error if all retries fail
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 2.9 Implement cleanup step
  - Remove GPG private key from keyring
  - Remove GPG public key from keyring
  - Clean up temporary files
  - Run in if: always() to ensure cleanup happens
  - _Requirements: 2.5_

- [ ]* 2.10 Write property test for artifact download
  - **Property 1: Artifact Download and RPM Location**
  - **Validates: Requirements 1.1, 1.2, 1.3**

- [ ]* 2.11 Write property test for signing round-trip
  - **Property 3: RPM Signing Round-Trip**
  - **Validates: Requirements 2.1, 2.3, 10.2, 10.3**

- [ ]* 2.12 Write property test for path construction
  - **Property 6: Directory Path Construction**
  - **Validates: Requirements 3.1, 3.4, 3.5**

- [ ]* 2.13 Write property test for metadata generation
  - **Property 9: Repository Metadata Generation**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

- [x] 3. Create delete package workflow (reuse from .ref/delete-package.yml)
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 3.1 Copy and adapt delete-package.yml from reference
  - Copy `.ref/delete-package.yml` to `.github/workflows/delete-package.yml`
  - Update directory paths from `repo/` to match new structure (no root `repo/` folder)
  - Verify input definitions: package_filename, package_name, distro, release, arch, build_type, dry_run
  - Verify input validation logic (specific file vs all versions mode)
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 3.2 Verify delete workflow logic
  - Verify package file location and deletion logic
  - Verify metadata update and HTML generation steps
  - Verify commit and push with retry logic (3 attempts with rebase)
  - Verify dry-run mode skips actual deletions
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ]* 3.3 Write property test for package deletion
  - **Property 15: Package Deletion by Filename**
  - **Validates: Requirements 7.1**

- [ ]* 3.4 Write property test for dry-run mode
  - **Property 17: Dry-Run Mode**
  - **Validates: Requirements 7.3**

- [x] 4. Create prune packages workflow (reuse from .ref/prune-packages.yml)
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 4.1 Copy and adapt prune-packages.yml from reference
  - Copy `.ref/prune-packages.yml` to `.github/workflows/prune-packages.yml`
  - Update directory paths from `repo/` to match new structure (no root `repo/` folder)
  - Verify schedule trigger (weekly on Sundays at 2 AM UTC)
  - Verify workflow_dispatch trigger for manual runs
  - Verify configuration loading from `.github/prune-config.yml`
  - _Requirements: 8.1_

- [x] 4.2 Copy prune configuration file
  - Copy `.ref/prune-config.yml` to `.github/prune-config.yml`
  - Verify default values: max_branches=2, max_versions=5
  - Verify configuration documentation
  - _Requirements: 8.1_

- [x] 4.3 Verify prune workflow logic
  - Verify distribution branch pruning (keep newest max_branches, preserve rawhide)
  - Verify package version pruning (keep newest max_versions per build_type)
  - Verify RPM version comparison using sort -V
  - Verify metadata update and HTML generation steps
  - Verify commit and push with retry logic (3 attempts with rebase)
  - _Requirements: 8.2, 8.3, 8.4, 8.5_

- [ ]* 4.4 Write property test for branch pruning
  - **Property 21: Distribution Branch Pruning**
  - **Validates: Requirements 8.2**

- [ ]* 4.5 Write property test for version pruning
  - **Property 22: Package Version Pruning**
  - **Validates: Requirements 8.3**

- [ ]* 4.6 Write property test for RPM version comparison
  - **Property 23: RPM Version Comparison**
  - **Validates: Requirements 8.4**

- [x] 5. Create repository configuration files
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 5.1 Create .repo file templates
  - Create `repo/stable.repo` with placeholder [owner]
  - Create `repo/testing.repo` with placeholder [owner]
  - Configure baseurl to point to GitHub Pages URL structure
  - Configure gpgkey to point to public.gpg in root
  - Set enabled=1 for stable, enabled=0 for testing
  - _Requirements: 9.3, 9.4, 9.5_

- [x] 5.2 Create initialization script
  - Create `scripts/init-repo-files.sh`
  - Query GitHub username using gh CLI
  - Read .repo template files
  - Replace [owner] placeholder with actual username
  - Write processed files to gh-pages root
  - _Requirements: 9.1, 9.2_

- [ ]* 5.3 Write property test for placeholder replacement
  - **Property 24: Repository File Placeholder Replacement**
  - **Validates: Requirements 9.2**

- [ ]* 5.4 Write property test for URL correctness
  - **Property 25: Repository File URL Correctness**
  - **Validates: Requirements 9.3, 9.4**

- [x] 6. Create GPG setup documentation and scripts
  - _Requirements: 2.1, 10.1, 10.2, 10.3, 10.4_

- [x] 6.1 Update GPG setup scripts
  - Review existing `scripts/setup-gpg.sh` and `scripts/setup-gpg-interactive.sh`
  - Ensure scripts generate keys without passphrase protection
  - Ensure scripts export public key to `repo/public.gpg`
  - Ensure scripts set all required GitHub secrets
  - Update documentation in `scripts/GPG_SETUP.md`
  - _Requirements: 2.1, 10.1_

- [x] 6.2 Create public key deployment instructions
  - Document manual process for copying public.gpg to gh-pages root
  - Include verification steps
  - Add to main README.md
  - _Requirements: 10.1_

- [x] 7. Update documentation
  - _Requirements: All_

- [x] 7.1 Update README.md
  - Document repository purpose and architecture
  - Add installation instructions for end users
  - Re: integration instructions for builder repositories, point them to the integration.md -- keep readme slim and focused.
  - _Requirements: 1.1, 9.3, 10.1_

- [x] 7.2 Update INTEGRATION.md
  - Document how builder repositories trigger workflows
  - Document workflow_dispatch parameters
  - Provide example workflow_dispatch calls
  - Document required parameters
  - Add examples for multiple distributions
  - _Requirements: 1.1_

- [ ] 8. Repository initialization and deployment
  - _Requirements: All_

- [x] 8.1 Initialize git repository
  - Commit all workflow files to main branch
  - Push main branch to remote
  - _Requirements: All_

- [x] 8.2 Run GPG setup
  - Execute `scripts/setup-gpg-interactive.sh`
  - Verify secrets are set in GitHub
  - Commit public.gpg to main branch
  - _Requirements: 2.1, 10.1_

- [-] 8.3 Initialize gh-pages branch





  - Create orphan gh-pages branch
  - Copy public.gpg testing.repo stable.repo to root
  - Create initial directory structure (fedora/43/x86_64/stable, fedora/43/x86_64/testing)
  - Ensure NO OTHER FILES FROM MAIN BRANCH ARE ADDED
  - Commit and push gh-pages
  - _Requirements: 9.1, 10.1_

- [-] 8.4 Enable GitHub Pages


  - Configure repository to serve from gh-pages branch
  - Verify site is accessible
  - Test downloading .repo files
  - Test importing public.gpg
  - _Requirements: 9.3, 10.1_

- [ ] 9. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
