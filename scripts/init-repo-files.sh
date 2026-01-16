#!/bin/bash
set -euo pipefail

# Initialize repository configuration files on gh-pages branch
# This script deploys .repo files and public GPG key to gh-pages

echo "Initializing repository configuration files..."

# Query GitHub username using gh CLI
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    exit 1
fi

OWNER=$(gh repo view --json owner -q .owner.login)
if [ -z "$OWNER" ]; then
    echo "Error: Could not determine repository owner"
    exit 1
fi

echo "Repository owner: $OWNER"

# Check if we're on gh-pages branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "gh-pages" ]; then
    echo "Warning: Not on gh-pages branch (current: $CURRENT_BRANCH)"
    echo "This script should be run on the gh-pages branch"
    exit 1
fi

# Check if template files exist in main branch
if [ ! -f "repo/abirkel-stable.repo" ] || [ ! -f "repo/abirkel-testing.repo" ]; then
    echo "Error: Template files not found in repo/ directory"
    echo "Make sure you have checked out the necessary files from main branch"
    exit 1
fi

# Copy .repo files to gh-pages root
echo "Copying abirkel-stable.repo..."
cp repo/abirkel-stable.repo abirkel-stable.repo
if [ ! -f "abirkel-stable.repo" ]; then
    echo "Error: Failed to copy abirkel-stable.repo"
    exit 1
fi
echo "Created abirkel-stable.repo"

echo "Copying abirkel-testing.repo..."
cp repo/abirkel-testing.repo abirkel-testing.repo
if [ ! -f "abirkel-testing.repo" ]; then
    echo "Error: Failed to copy abirkel-testing.repo"
    exit 1
fi
echo "Created abirkel-testing.repo"

# Copy public GPG key if it exists
if [ -f "repo/public.gpg" ]; then
    echo "Copying public.gpg..."
    cp repo/public.gpg public.gpg
    echo "Created public.gpg"
else
    echo "Warning: public.gpg not found in repo/ directory"
fi

echo "Successfully initialized repository configuration files"
echo "Files created:"
echo "  - abirkel-stable.repo"
echo "  - abirkel-testing.repo"
if [ -f "public.gpg" ]; then
    echo "  - public.gpg"
fi
echo ""
echo "Next steps:"
echo "  1. Verify the files contain correct URLs"
echo "  2. Commit and push to gh-pages branch"
