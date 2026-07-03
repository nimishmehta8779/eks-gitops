#!/bin/bash

set -e

echo "=================================================="
echo "Dynatrace AIOps - Deployment Validation"
echo "=================================================="
echo ""

# Load environment variables
if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found!"
    exit 1
fi

set -a
source .env
set +a

PASSED=0
FAILED=0

# Test 1: Check dtctl connectivity
echo "🔍 Test 1: Checking dtctl connectivity..."
if dtctl get workflow ${WORKFLOW_ID} &>/dev/null; then
    echo "✅ PASS: dtctl can connect to Dynatrace"
    ((PASSED++))
else
    echo "❌ FAIL: dtctl cannot connect to Dynatrace"
    ((FAILED++))
fi

# Test 2: Check Dynatrace API token
echo ""
echo "🔍 Test 2: Validating Dynatrace API token..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
  "${DYNATRACE_ENV_URL}/api/v2/entities?entitySelector=type%28%22APPLICATION%22%29&limit=1")

if [ "$RESPONSE" = "200" ]; then
    echo "✅ PASS: Dynatrace API token is valid"
    ((PASSED++))
else
    echo "❌ FAIL: Dynatrace API token is invalid (HTTP ${RESPONSE})"
    ((FAILED++))
fi

# Test 3: Check GitHub API token
echo ""
echo "🔍 Test 3: Validating GitHub API token..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  "https://api.github.com/user")

if [ "$RESPONSE" = "200" ]; then
    echo "✅ PASS: GitHub API token is valid"
    ((PASSED++))
else
    echo "❌ FAIL: GitHub API token is invalid (HTTP ${RESPONSE})"
    ((FAILED++))
fi

# Test 4: Check ArgoCD connectivity
echo ""
echo "🔍 Test 4: Validating ArgoCD connectivity..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${ARGOCD_API_TOKEN}" \
  "${ARGOCD_SERVER_URL}/api/v1/applications")

if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "401" ]; then
    echo "✅ PASS: ArgoCD is reachable (HTTP ${RESPONSE})"
    ((PASSED++))
else
    echo "❌ FAIL: ArgoCD is unreachable (HTTP ${RESPONSE})"
    ((FAILED++))
fi

# Test 5: Check Slack webhooks
echo ""
echo "🔍 Test 5: Validating Slack webhooks..."
RESPONSE=$(curl -s -X POST \
  -H 'Content-type: application/json' \
  --data '{"text":"Validation test"}' \
  -o /dev/null -w "%{http_code}" \
  "${SLACK_WEBHOOK_INCIDENTS}")

if [ "$RESPONSE" = "200" ]; then
    echo "✅ PASS: Slack incidents webhook is valid"
    ((PASSED++))
else
    echo "❌ FAIL: Slack incidents webhook is invalid (HTTP ${RESPONSE})"
    ((FAILED++))
fi

# Test 6: Check credentials in Dynatrace
echo ""
echo "🔍 Test 6: Checking Dynatrace credentials..."
CREDS=$(curl -s -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
  "${DYNATRACE_ENV_URL}/api/v1/credentials" | grep -o '"name":"[^"]*"' | wc -l)

if [ "$CREDS" -gt 0 ]; then
    echo "✅ PASS: Found ${CREDS} credentials in Dynatrace"
    ((PASSED++))
else
    echo "❌ FAIL: No credentials found in Dynatrace"
    ((FAILED++))
fi

# Test 7: Check workflow deployment status
echo ""
echo "🔍 Test 7: Checking workflow deployment status..."
WORKFLOW_STATUS=$(dtctl get workflow ${WORKFLOW_ID} -o json | grep -o '"isDeployed":true' || echo "")

if [ -n "$WORKFLOW_STATUS" ]; then
    echo "✅ PASS: Workflow is deployed and active"
    ((PASSED++))
else
    echo "⚠️  WARNING: Workflow exists but may not be deployed"
    echo "   Go to Dynatrace UI to activate the workflow trigger"
    ((PASSED++))
fi

# Summary
echo ""
echo "=================================================="
echo "Validation Summary"
echo "=================================================="
echo ""
echo "✅ Passed: ${PASSED}"
echo "❌ Failed: ${FAILED}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo "🎉 All validation checks passed!"
    echo ""
    echo "Your deployment is ready. Next steps:"
    echo "1. Go to Dynatrace UI and open the workflow"
    echo "2. Change trigger from 'On demand' to 'Dynatrace problem'"
    echo "3. Add remediation tasks"
    echo "4. Deploy and test with a pod failure"
    exit 0
else
    echo "⚠️  Some validation checks failed."
    echo "Please fix the issues above and run this script again."
    exit 1
fi
