#!/bin/bash
set -e

echo "=========================================="
echo "  RPM Repository Setup"
echo "=========================================="
echo ""
echo "This script will guide you through setting up:"
echo "  1. GPG key generation and GitHub secrets"
echo "  2. Repository permissions and branch protection"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "   Install it from: https://cli.github.com/"
    exit 1
fi
echo "✓ GitHub CLI installed"

if ! command -v gpg &> /dev/null; then
    echo "❌ GPG is not installed."
    echo "   Install it using: sudo apt-get install gnupg"
    exit 1
fi
echo "✓ GPG installed"

if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "   Run: gh auth login"
    exit 1
fi
echo "✓ GitHub CLI authenticated"

echo ""
echo "=========================================="
echo "  Step 1: GPG Key Setup"
echo "=========================================="
echo ""
read -r -p "Generate GPG key and set up secrets? (y/n): " SETUP_GPG

if [ "$SETUP_GPG" = "y" ]; then
    bash setup-gpg-interactive.sh
    echo ""
    echo "✓ GPG setup complete"
else
    echo "⊘ Skipping GPG setup"
fi

echo ""
echo "=========================================="
echo "  Step 2: Repository Permissions"
echo "=========================================="
echo ""
read -r -p "Configure repository permissions? (y/n): " SETUP_PERMS

if [ "$SETUP_PERMS" = "y" ]; then
    bash setup-permissions.sh
    echo ""
    echo "✓ Permissions setup complete"
else
    echo "⊘ Skipping permissions setup"
fi

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Summary of completed steps:"
if [ "$SETUP_GPG" = "y" ]; then
    echo "  ✓ GPG key generated and secrets configured"
    echo "    - Public key: repo/public.gpg"
    echo "    - Secrets: GPG_PRIVATE_KEY, GPG_PRIVATE_KEY_PASS, GPG_KEY_ID"
fi
if [ "$SETUP_PERMS" = "y" ]; then
    echo "  ✓ Repository permissions configured"
    echo "    - Documentation: PERMISSIONS.md"
fi

echo ""
echo "Next steps:"
if [ "$SETUP_GPG" = "y" ]; then
    echo "  1. Commit and push repo/public.gpg:"
    echo "     git add repo/public.gpg"
    echo "     git commit -m 'Add GPG public key'"
    echo "     git push"
fi
echo "  2. Review the documentation:"
echo "     - GPG_SETUP.md"
echo "     - PERMISSIONS_GUIDE.md"
if [ "$SETUP_PERMS" = "y" ]; then
    echo "     - PERMISSIONS.md"
fi
echo "  3. Test the workflow with a builder repository"
echo ""
