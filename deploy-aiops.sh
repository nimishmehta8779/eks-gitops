#!/bin/bash

set -e

echo "=================================================="
echo "Dynatrace AIOps - EKS GitOps Auto-Remediation"
echo "Deployment Script"
echo "=================================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found!"
    echo "Please copy .env.template to .env and fill in your credentials:"
    echo "  cp .env.template .env"
    echo "  nano .env"
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

echo "✅ Configuration loaded from .env"
echo ""

# Verify required tools
echo "🔍 Checking prerequisites..."
if ! command -v dtctl &> /dev/null; then
    echo "❌ ERROR: dtctl not found. Please install dtctl first."
    exit 1
fi
echo "✅ dtctl found: $(dtctl version | head -1)"

if ! command -v curl &> /dev/null; then
    echo "❌ ERROR: curl not found."
    exit 1
fi
echo "✅ curl found"

echo ""
echo "=================================================="
echo "Step 1: Create Credential Vault Entries"
echo "=================================================="
echo ""

echo "ℹ️  PagerDuty connection: ${PAGERDUTY_CONNECTION_NAME}"
echo "   (Already configured in Dynatrace)"
echo ""

# Create Dynatrace API Token credential
echo "📝 Creating Dynatrace API Token credential..."
curl -s -X POST "${DYNATRACE_ENV_URL}/api/v1/credentials" \
  -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "dynatrace_api_token",
    "type": "token",
    "token": "'"${DYNATRACE_API_TOKEN}"'",
    "scope": "ALL"
  }' > /dev/null && echo "✅ Dynatrace API Token credential created" || echo "⚠️  Dynatrace credential may already exist"

# Create ArgoCD API Token credential
echo "📝 Creating ArgoCD API Token credential..."
curl -s -X POST "${DYNATRACE_ENV_URL}/api/v1/credentials" \
  -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "argocd_api_token",
    "type": "token",
    "token": "'"${ARGOCD_API_TOKEN}"'",
    "scope": "ALL"
  }' > /dev/null && echo "✅ ArgoCD API Token credential created" || echo "⚠️  ArgoCD credential may already exist"

# Create GitHub Token credential
echo "📝 Creating GitHub Token credential..."
curl -s -X POST "${DYNATRACE_ENV_URL}/api/v1/credentials" \
  -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "github_token",
    "type": "token",
    "token": "'"${GITHUB_TOKEN}"'",
    "scope": "ALL"
  }' > /dev/null && echo "✅ GitHub Token credential created" || echo "⚠️  GitHub credential may already exist"

# Create Slack Incidents Webhook credential
echo "📝 Creating Slack Incidents Webhook credential..."
curl -s -X POST "${DYNATRACE_ENV_URL}/api/v1/credentials" \
  -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "slack_webhook_incidents",
    "type": "token",
    "token": "'"${SLACK_WEBHOOK_INCIDENTS}"'",
    "scope": "ALL"
  }' > /dev/null && echo "✅ Slack Incidents Webhook credential created" || echo "⚠️  Slack incidents credential may already exist"

# Create Slack Critical Webhook credential
echo "📝 Creating Slack Critical Webhook credential..."
curl -s -X POST "${DYNATRACE_ENV_URL}/api/v1/credentials" \
  -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "slack_webhook_critical",
    "type": "token",
    "token": "'"${SLACK_WEBHOOK_CRITICAL}"'",
    "scope": "ALL"
  }' > /dev/null && echo "✅ Slack Critical Webhook credential created" || echo "⚠️  Slack critical credential may already exist"

echo ""
echo "=================================================="
echo "Step 2: Deploy Workflow"
echo "=================================================="
echo ""

if [ ! -f dynatrace-workflow-executable.json ]; then
    echo "❌ ERROR: dynatrace-workflow-executable.json not found!"
    exit 1
fi

echo "📝 Deploying workflow: ${WORKFLOW_NAME}"
dtctl apply -f dynatrace-workflow-executable.json && echo "✅ Workflow deployed successfully" || echo "❌ Workflow deployment failed"

echo ""
echo "=================================================="
echo "Step 3: Verify Deployment"
echo "=================================================="
echo ""

# Verify workflow exists
echo "🔍 Verifying workflow..."
WORKFLOW_INFO=$(dtctl get workflow ${WORKFLOW_ID} -o json 2>/dev/null)

if [ -z "$WORKFLOW_INFO" ]; then
    echo "⚠️  Could not verify workflow. Check Dynatrace UI."
else
    IS_DEPLOYED=$(echo "$WORKFLOW_INFO" | grep -o '"isDeployed":true' || echo "")
    if [ -n "$IS_DEPLOYED" ]; then
        echo "✅ Workflow is deployed and active"
    else
        echo "⚠️  Workflow exists but not deployed. Check Dynatrace UI to enable."
    fi
fi

echo ""
echo "=================================================="
echo "Step 4: Credentials Summary"
echo "=================================================="
echo ""

echo "✅ Dynatrace API Token: dynatrace_api_token"
echo "✅ ArgoCD API Token: argocd_api_token"
echo "✅ GitHub Token: github_token"
echo "✅ Slack Incidents Webhook: slack_webhook_incidents"
echo "✅ Slack Critical Webhook: slack_webhook_critical"

echo ""
echo "=================================================="
echo "✨ Deployment Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Go to: ${DYNATRACE_ENV_URL}/ui/apps/dynatrace.automation/workflows"
echo "2. Find: ${WORKFLOW_NAME}"
echo "3. Set trigger to: Dynatrace Problem (for auto-trigger)"
echo "4. Add tasks for remediation actions"
echo ""
echo "Organization: ${ORG_NAME}"
echo "Workflow ID: ${WORKFLOW_ID}"
echo ""
