# rpm-repo

![Repo Type](https://img.shields.io/badge/type-rpm_repository-blue)
![Signing](https://img.shields.io/badge/signing-GPG-green)
![Automation](https://img.shields.io/badge/ci-github_actions-yellow)

**rpm-repo** is the central signing and publishing repository for all RPM packages built across my GitHub projects.

Builder repositories produce unsigned RPMs → this repository signs them with a trusted GPG key → then publishes them to a structured `gh-pages` RPM repository with incremental metadata updates.

This repository contains:
- A **reusable GitHub Actions workflow** for signing & publishing RPMs  
- A **composite GitHub Action** used internally by the workflow  
- A public-facing **RPM repository** at: **https://abirkel.github.io/rpm-repo/**  
- The **public GPG key** used for verifying signatures

## Installing Packages

1. Download the repository configuration:

```bash
sudo curl -o /etc/yum.repos.d/rpm-repo.repo \
  https://abirkel.github.io/rpm-repo/repo/rpm-repo.repo
```

2. Import the GPG public key:

```bash
sudo rpm --import https://abirkel.github.io/rpm-repo/repo/public.gpg
```

3. Install packages:

```bash
sudo dnf install <package-name>
```

## Repository Structure

```
├── fedora/
│   ├── 43/x86_64/
│   │   ├── repodata/
│   │   └── *.rpm
│   └── [other releases]/
├── public.gpg
└── rpm-repo.repo
```

## Integration

See [INTEGRATION.md](INTEGRATION.md) for instructions on integrating builder repositories with this central signing repository.
