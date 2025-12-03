#!/bin/bash
set -euo pipefail

# Initialize repository configuration files on gh-pages branch
# This script replaces [owner] placeholder with actual GitHub username

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
if [ ! -f "repo/stable.repo" ] || [ ! -f "repo/testing.repo" ]; then
    echo "Error: Template files not found in repo/ directory"
    echo "Make sure you have checked out the necessary files from main branch"
    exit 1
fi

# Process stable.repo
echo "Processing stable.repo..."
sed "s/\[owner\]/$OWNER/g" repo/stable.repo > stable.repo
if [ ! -f "stable.repo" ]; then
    echo "Error: Failed to create stable.repo"
    exit 1
fi
echo "Created stable.repo"

# Process testing.repo
echo "Processing testing.repo..."
sed "s/\[owner\]/$OWNER/g" repo/testing.repo > testing.repo
if [ ! -f "testing.repo" ]; then
    echo "Error: Failed to create testing.repo"
    exit 1
fi
echo "Created testing.repo"

# Verify placeholder replacement
if grep -q "\[owner\]" stable.repo testing.repo; then
    echo "Error: Placeholder [owner] still present in output files"
    exit 1
fi

echo "Successfully initialized repository configuration files"
echo "Files created:"
echo "  - stable.repo"
echo "  - testing.repo"
echo ""
echo "Next steps:"
echo "  1. Verify the files contain correct URLs"
echo "  2. Commit and push to gh-pages branch"
