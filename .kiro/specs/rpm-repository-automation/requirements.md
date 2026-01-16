# Requirements Document

## Introduction

This specification defines an automated RPM repository system hosted on GitHub Pages. The system provides centralized GPG signing and publishing services for RPM packages built in separate builder repositories. Builder repositories trigger workflows in this repository via workflow_dispatch, which downloads their artifacts, signs the RPMs with a trusted GPG key, publishes them to a structured repository on the gh-pages branch, and maintains browsable HTML indexes.

## Glossary

- **RPM Repository System**: The complete automated system for signing, publishing, and managing RPM packages on GitHub Pages
- **Builder Repository**: External GitHub repository that builds unsigned RPM packages and triggers publishing workflows
- **Workflow Dispatch**: GitHub Actions mechanism allowing external repositories to trigger workflows with parameters
- **GPG Signing**: Process of cryptographically signing RPM packages with a private GPG key
- **Repository Metadata**: YUM/DNF metadata files (repodata) that describe available packages
- **Build Type**: Classification of packages as either "stable" (production-ready) or "testing" (pre-release)
- **Pruning**: Automated removal of old package versions and distribution releases
- **HTML Index**: Human-browsable directory listing generated for GitHub Pages

## Requirements

### Requirement 1

**User Story:** As a builder repository maintainer, I want to trigger RPM signing and publishing via workflow dispatch, so that my unsigned RPMs are automatically signed and published to the central repository.

#### Acceptance Criteria

1. WHEN a builder repository triggers the workflow dispatch THEN the RPM Repository System SHALL accept parameters for builder_repo, run_id, artifact_name, distro, release, arch, and build_type
2. WHEN the workflow is triggered THEN the RPM Repository System SHALL download the artifact from the specified builder repository using the GitHub CLI
3. WHEN the artifact is downloaded THEN the RPM Repository System SHALL locate the RPM file within the artifact directory
4. WHEN multiple RPM files exist in the artifact THEN the RPM Repository System SHALL process the first RPM file found
5. WHEN the artifact download fails THEN the RPM Repository System SHALL terminate with a clear error message indicating the failure reason

### Requirement 2

**User Story:** As a repository administrator, I want RPM packages to be signed with a trusted GPG key, so that users can verify package authenticity.

#### Acceptance Criteria

1. WHEN an unsigned RPM is provided THEN the RPM Repository System SHALL sign the RPM using the GPG private key stored in GitHub Secrets
2. WHEN signing an RPM THEN the RPM Repository System SHALL configure GPG for non-interactive operation using loopback pinentry mode
3. WHEN the RPM is signed THEN the RPM Repository System SHALL verify the signature is valid before proceeding
4. WHEN signature verification fails THEN the RPM Repository System SHALL terminate with an error and SHALL NOT publish the RPM
5. WHEN signing completes THEN the RPM Repository System SHALL remove the GPG private key from the runner environment

### Requirement 3

**User Story:** As a repository administrator, I want signed RPMs published to a structured directory hierarchy, so that packages are organized by distribution, release, architecture, and build type.

#### Acceptance Criteria

1. WHEN publishing an RPM THEN the RPM Repository System SHALL place the RPM in the directory path fedora/{release}/{arch}/{build_type}/
2. WHEN the target directory does not exist THEN the RPM Repository System SHALL create the complete directory structure
3. WHEN an RPM with the same filename already exists THEN the RPM Repository System SHALL overwrite the existing file
4. WHEN the build_type is "stable" THEN the RPM Repository System SHALL publish to the stable subdirectory
5. WHEN the build_type is "testing" THEN the RPM Repository System SHALL publish to the testing subdirectory

### Requirement 4

**User Story:** As a package user, I want YUM/DNF repository metadata to be automatically updated, so that package managers can discover and install packages.

#### Acceptance Criteria

1. WHEN a new RPM is published THEN the RPM Repository System SHALL update the repository metadata using createrepo_c
2. WHEN repository metadata already exists THEN the RPM Repository System SHALL perform an incremental update using the --update flag
3. WHEN repository metadata does not exist THEN the RPM Repository System SHALL create new metadata
4. WHEN metadata generation completes THEN the RPM Repository System SHALL validate the repomd.xml file is well-formed XML
5. WHEN metadata validation fails THEN the RPM Repository System SHALL terminate with an error

### Requirement 5

**User Story:** As a repository browser, I want human-readable HTML directory listings, so that I can browse available packages through a web browser.

#### Acceptance Criteria

1. WHEN repository content changes THEN the RPM Repository System SHALL regenerate HTML directory listings for all directories
2. WHEN generating HTML listings THEN the RPM Repository System SHALL use the jayanta525/github-pages-directory-listing action
3. WHEN HTML generation completes THEN the RPM Repository System SHALL include the generated index.html files in the commit
4. WHEN a user visits the repository URL THEN the RPM Repository System SHALL display a browsable directory structure
5. WHEN a directory contains RPM files THEN the HTML listing SHALL display the RPM filenames with file sizes

### Requirement 6

**User Story:** As a repository administrator, I want changes automatically committed to the gh-pages branch, so that the repository is immediately available to users.

#### Acceptance Criteria

1. WHEN publishing completes THEN the RPM Repository System SHALL commit all changes to the gh-pages branch
2. WHEN committing changes THEN the RPM Repository System SHALL use a descriptive commit message including the RPM filename and target path
3. WHEN pushing to gh-pages fails THEN the RPM Repository System SHALL retry up to 3 times with exponential backoff
4. WHEN a push conflict occurs THEN the RPM Repository System SHALL attempt to rebase on the latest gh-pages branch
5. WHEN all retry attempts fail THEN the RPM Repository System SHALL terminate with an error

### Requirement 7

**User Story:** As a repository administrator, I want to manually delete specific packages, so that I can remove incorrect or problematic packages from the repository.

#### Acceptance Criteria

1. WHEN a package filename is provided THEN the RPM Repository System SHALL locate and delete the specified RPM file
2. WHEN a package name with distribution details is provided THEN the RPM Repository System SHALL delete all versions of the package in the specified location
3. WHEN dry_run mode is enabled THEN the RPM Repository System SHALL report what would be deleted without making changes
4. WHEN a package is deleted THEN the RPM Repository System SHALL regenerate repository metadata for the affected directory
5. WHEN the last package in a directory is deleted THEN the RPM Repository System SHALL remove empty directories

### Requirement 8

**User Story:** As a repository administrator, I want old package versions and distribution releases automatically pruned, so that the repository size remains manageable.

#### Acceptance Criteria

1. WHEN the prune workflow runs THEN the RPM Repository System SHALL read configuration from prune-config.yml in the main branch
2. WHEN pruning distribution branches THEN the RPM Repository System SHALL keep only the newest N releases as specified in max_branches
3. WHEN pruning package versions THEN the RPM Repository System SHALL keep only the newest M versions per package as specified in max_versions
4. WHEN comparing package versions THEN the RPM Repository System SHALL use RPM version comparison semantics
5. WHEN the "rawhide" release exists THEN the RPM Repository System SHALL always preserve it regardless of max_branches setting

### Requirement 9

**User Story:** As a repository administrator, I want repository configuration files available for download, so that users can easily configure their package managers.

#### Acceptance Criteria

1. WHEN the repository is initialized THEN the RPM Repository System SHALL copy .repo files to the gh-pages root directory
2. WHEN copying .repo files THEN the RPM Repository System SHALL replace the [owner] placeholder with the actual GitHub username
3. WHEN a user downloads a .repo file THEN the file SHALL contain the correct baseurl pointing to the GitHub Pages URL
4. WHEN a .repo file references the GPG key THEN the URL SHALL point to the public.gpg file in the gh-pages root
5. WHEN the stable.repo file is used THEN the repository SHALL be enabled by default

### Requirement 10

**User Story:** As a package user, I want to verify package signatures, so that I can ensure packages have not been tampered with.

#### Acceptance Criteria

1. WHEN the repository is initialized THEN the public GPG key SHALL be available at the gh-pages root as public.gpg
2. WHEN a user imports the public key THEN the RPM Repository System SHALL allow signature verification of all signed packages
3. WHEN verifying a package signature THEN the signature SHALL match the public key
4. WHEN a package is unsigned THEN RPM tools SHALL reject the package if gpgcheck is enabled
5. WHEN the public key is updated THEN all previously signed packages SHALL remain verifiable with the old key until re-signed

### Requirement 11

**User Story:** As a repository administrator, I want sign and publish operations to execute sequentially in a queue, so that concurrent modifications to the gh-pages branch do not cause conflicts.

#### Acceptance Criteria

1. WHEN multiple sign and publish workflows are triggered simultaneously THEN the RPM Repository System SHALL queue the workflows to execute one at a time
2. WHEN a sign and publish workflow is running THEN subsequent workflows SHALL wait until the current workflow completes
3. WHEN a queued workflow starts THEN the RPM Repository System SHALL operate on the latest gh-pages branch state
4. WHEN a workflow is queued THEN the workflow SHALL display its queue position in the GitHub Actions UI
5. WHEN a workflow completes or fails THEN the next queued workflow SHALL start immediately
