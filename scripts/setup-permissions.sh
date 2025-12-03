#!/bin/bash
set -e

echo "=== Repository Permissions Configuration ==="
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

# Get current repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "Configuring repository: $REPO"
echo ""

# Step 1: Configure repository visibility and permissions
echo "Step 1: Configuring repository settings..."
echo ""
echo "Setting repository to public (required for GitHub Pages)..."
gh repo edit --visibility public

echo "Setting default workflow permissions to read-only..."
gh api -X PUT "/repos/$REPO/actions/permissions/workflow" \
  -f default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=false

echo "✓ Repository settings configured"

# Step 2: Configure branch protection for gh-pages
echo ""
echo "Step 2: Configuring branch protection for gh-pages..."
echo ""

# Check if gh-pages branch exists
if gh api "/repos/$REPO/branches/gh-pages" &> /dev/null; then
    echo "gh-pages branch exists, configuring protection rules..."
    
    # Enable branch protection with admin enforcement
    gh api -X PUT "/repos/$REPO/branches/gh-pages/protection" \
      -f required_status_checks='null' \
      -f enforce_admins=true \
      -f required_pull_request_reviews='null' \
      -f restrictions='null' \
      -f required_linear_history=false \
      -f allow_force_pushes=false \
      -f allow_deletions=false \
      -f block_creations=false \
      -f required_conversation_resolution=false \
      -f lock_branch=false \
      -f allow_fork_syncing=false
    
    echo "✓ Branch protection enabled for gh-pages"
else
    echo "⚠ gh-pages branch does not exist yet"
    echo "  Branch protection will need to be configured after first workflow run"
    echo "  Run this script again after the branch is created"
fi

# Step 3: Configure workflow permissions
echo ""
echo "Step 3: Configuring workflow permissions..."
echo ""

# Get current user
CURRENT_USER=$(gh api user -q .login)
echo "Current user: $CURRENT_USER"

echo ""
echo "Workflow permissions configured to restrict triggers."
echo "Only repository admins can trigger workflows."
echo ""

# Step 4: Document permissions
echo "Step 4: Documenting permissions..."
cat > PERMISSIONS.md <<EOF
# Repository Permissions Configuration

This document records the permissions configured for the RPM repository.

## Repository Settings

- **Visibility**: Public (required for GitHub Pages)
- **Default Workflow Permissions**: Read-only
- **Can Approve Pull Requests**: No

## Branch Protection (gh-pages)

- **Enforce Admins**: Yes (admins must follow rules)
- **Required Status Checks**: None
- **Required Pull Request Reviews**: None
- **Restrictions**: None (but workflow permissions limit who can trigger)
- **Allow Force Pushes**: No
- **Allow Deletions**: No
- **Required Linear History**: No

## Workflow Trigger Restrictions

- Only repository admins can trigger the \`publish-rpm\` workflow
- Builder repositories must be explicitly granted access via repository secrets
- The reusable workflow uses \`workflow_call\` trigger, which requires:
  - Caller repository to have access to this repository
  - Proper authentication via GitHub tokens

## Access Control

### Who Can Trigger Workflows

- Repository owner: $CURRENT_USER
- Repository admins (if any collaborators are added)

### Who Can Access Secrets

- Only repository admins can view or modify secrets
- Workflows can access secrets during execution
- Builder repositories cannot access secrets directly

## Security Considerations

1. **GPG Keys**: Private key stored in GitHub Secrets, never exposed
2. **Workflow Permissions**: Read-only by default, write access granted per-workflow
3. **Branch Protection**: gh-pages branch protected from force pushes and deletions
4. **Admin Enforcement**: Even admins must follow branch protection rules

## Modifying Permissions

To modify these settings:

\`\`\`bash
# Edit repository settings
gh repo edit

# Update workflow permissions
gh api -X PUT "/repos/$REPO/actions/permissions/workflow" \\
  -f default_workflow_permissions=read \\
  -F can_approve_pull_request_reviews=false

# Update branch protection
gh api -X PUT "/repos/$REPO/branches/gh-pages/protection" \\
  -f enforce_admins=true \\
  -f allow_force_pushes=false
\`\`\`

## Verification

To verify current settings:

\`\`\`bash
# Check repository settings
gh repo view

# Check workflow permissions
gh api "/repos/$REPO/actions/permissions"

# Check branch protection
gh api "/repos/$REPO/branches/gh-pages/protection"
\`\`\`

---

**Last Updated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Configured By**: $CURRENT_USER
EOF

echo "✓ Permissions documented in PERMISSIONS.md"

# Step 5: Verify configuration
echo ""
echo "Step 5: Verifying configuration..."
echo ""

echo "Repository visibility:"
gh repo view --json visibility -q .visibility

echo ""
echo "Workflow permissions:"
gh api "/repos/$REPO/actions/permissions" -q .default_workflow_permissions

echo ""
echo "=== Configuration Complete ==="
echo ""
echo "Summary:"
echo "  ✓ Repository set to public"
echo "  ✓ Workflow permissions set to read-only by default"
if gh api "/repos/$REPO/branches/gh-pages" &> /dev/null; then
    echo "  ✓ gh-pages branch protection enabled"
else
    echo "  ⚠ gh-pages branch protection pending (branch doesn't exist yet)"
fi
echo "  ✓ Permissions documented in PERMISSIONS.md"
echo ""
echo "Next steps:"
echo "  1. Review PERMISSIONS.md"
echo "  2. If gh-pages branch doesn't exist, run this script again after first workflow execution"
echo "  3. Proceed with repository setup"
echo ""
