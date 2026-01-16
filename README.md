# RPM Repository Automation

![Repo Type](https://img.shields.io/badge/type-rpm_repository-blue)
![Signing](https://img.shields.io/badge/signing-GPG-green)
![Automation](https://img.shields.io/badge/ci-github_actions-yellow)
![Pages](https://img.shields.io/badge/hosted-github_pages-blue)

A centralized RPM repository that provides automated GPG signing and publishing for my project packages.

## Purpose

This repository serves as a central hub for signing and publishing RPM packages:

- **Builder repositories** produce unsigned RPM packages and trigger workflows in this repository
- **This repository** downloads artifacts, signs RPMs with a trusted GPG key, and publishes them to GitHub Pages
- **End users** install packages from the public repository with verified GPG signatures

## Installing Packages

### 1. Add the Repository

For **stable** packages (recommended):

```bash
sudo curl -o /etc/yum.repos.d/abirkel-stable.repo \
  https://abirkel.github.io/rpm-repo/abirkel-stable.repo
```

For **testing** packages:

```bash
sudo curl -o /etc/yum.repos.d/abirkel-testing.repo \
  https://abirkel.github.io/rpm-repo/abirkel-testing.repo
```

### 2. Install Packages

```bash
sudo dnf install <package-name>
```

### 3. Browse Available Packages

Visit the repository in your browser:

```
https://abirkel.github.io/rpm-repo/
```

Navigate through the directory structure to see available packages organized by distribution, release, build type, and architecture.

## Builder Integration

See [INTEGRATION.md](INTEGRATION.md) for instructions on integrating builder repositories with this central signing and publishing repository.
