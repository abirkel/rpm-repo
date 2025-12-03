#!/bin/bash
set -e

echo "=== RPM Repository GPG Key Setup ==="
echo ""
echo "This script will:"
echo "1. Generate a new GPG key pair (without passphrase protection)"
echo "2. Export the public key to repo/public.gpg"
echo "3. Export the private key as base64"
echo "4. Store keys in GitHub repository secrets"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI."
    echo "Run: gh auth login"
    exit 1
fi

# Generate GPG key
echo "Step 1: Generating GPG key pair..."
echo ""
echo "Note: The key will be generated WITHOUT passphrase protection"
echo "for automated signing in GitHub Actions workflows."
echo ""
read -r -p "Press Enter to continue..."

# Create GPG key generation batch file
cat > /tmp/gpg-gen-key.batch <<EOF
%echo Generating RPM repository signing key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: GitHub Actions
Name-Email: 41898282+github-actions[bot]@users.noreply.github.com
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF

echo ""
echo "Generating key (this may take a moment)..."
gpg --batch --generate-key /tmp/gpg-gen-key.batch

# Get the key ID
KEY_ID=$(gpg --list-keys --with-colons "GitHub Actions" | grep '^fpr' | head -1 | cut -d: -f10)

if [ -z "$KEY_ID" ]; then
    echo "Error: Failed to generate GPG key"
    exit 1
fi

echo ""
echo "✓ GPG key generated successfully!"
echo "  Key ID: $KEY_ID"

# Step 2: Export public key
echo ""
echo "Step 2: Exporting public key to repo/public.gpg..."
mkdir -p repo
gpg --export -a "$KEY_ID" > repo/public.gpg
echo "✓ Public key exported to repo/public.gpg"

# Step 3: Export private key as base64
echo ""
echo "Step 3: Exporting private key as base64..."
PRIVATE_KEY_B64=$(gpg --export-secret-key "$KEY_ID" | base64 -w 0)
echo "✓ Private key exported"

# Step 4: Set GitHub secrets
echo ""
echo "Step 4: Setting up GitHub secrets..."

echo "Setting GPG_PRIVATE_KEY secret..."
echo "$PRIVATE_KEY_B64" | gh secret set GPG_PRIVATE_KEY

echo "Setting GPG_PRIVATE_KEY_PASS secret (empty for no passphrase)..."
echo "" | gh secret set GPG_PRIVATE_KEY_PASS

echo "Setting GPG_KEY_ID secret..."
echo "$KEY_ID" | gh secret set GPG_KEY_ID

echo ""
echo "✓ All secrets set successfully!"

# Step 5: Verify secrets
echo ""
echo "Step 5: Verifying secrets..."
gh secret list

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Commit and push repo/public.gpg to your repository:"
echo "   git add repo/public.gpg"
echo "   git commit -m 'Add GPG public key for package signing'"
echo "   git push"
echo ""
echo "2. Deploy public.gpg to gh-pages branch (see README.md for instructions)"
echo ""
echo "Key Information:"
echo "  Key ID: $KEY_ID"
echo "  Public Key: repo/public.gpg"
echo "  Secrets: GPG_PRIVATE_KEY, GPG_PRIVATE_KEY_PASS, GPG_KEY_ID"
echo "  Passphrase: None (key generated without passphrase protection)"
echo ""

# Cleanup
rm -f /tmp/gpg-gen-key.batch
