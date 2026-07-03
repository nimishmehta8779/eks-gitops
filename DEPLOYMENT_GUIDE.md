# Dynatrace AIOps - EKS GitOps Auto-Remediation Deployment Guide

Complete automated deployment for the EKS GitOps Auto-Remediation workflow.

---

## Quick Start (5 minutes)

```bash
# 1. Clone and setup
git clone https://github.com/nimishmehta8779/dynatrace-aiops.git && cd dynatrace-aiops

# 2. Configure credentials
cp .env.template .env
nano .env  # Fill in your API tokens

# 3. Deploy
chmod +x deploy-aiops.sh && ./deploy-aiops.sh

# 4. Validate
chmod +x validate-deployment.sh && ./validate-deployment.sh

# 5. Done! Workflow is now active
# Organization: nimishmehta8779
```

---

## Detailed Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/nimishmehta8779/dynatrace-aiops.git
cd dynatrace-aiops
```

### Step 2: Configure Environment Variables

Copy the template and fill in your credentials:

```bash
cp .env.template .env
nano .env
```

#### Required Credentials:

**Dynatrace:**
```
DYNATRACE_ENV_URL=https://YOUR_ENV.apps.dynatrace.com
DYNATRACE_API_TOKEN=dt0c01.XXXXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Get token: **Settings → Access Management → API Tokens**
- Required scopes: `entities.read`, `logs.read`, `metrics.read`, `events.read`

**PagerDuty:**
```
PAGERDUTY_CONNECTION_NAME=PagerDuty-Production-Alerts
PAGERDUTY_SERVICE_ID=P5DXFI2
PAGERDUTY_ESCALATION_POLICY=P552ZH8
```

Note: Uses existing Dynatrace connection (already configured)

**GitHub:**
```
GITHUB_TOKEN=ghp_XXXXXXXXXXXX
GITHUB_REPO=your-org/eks-gitops
```

Get token: **GitHub → Settings → Developer Settings → Personal Access Tokens**
- Required scopes: `repo`, `workflow`

**ArgoCD:**
```
ARGOCD_SERVER_URL=http://localhost:8080
ARGOCD_API_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Get token: `argocd account generate-token --account dynatrace-automation`

**Slack:**
```
SLACK_WEBHOOK_INCIDENTS=https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXXXXX
SLACK_WEBHOOK_CRITICAL=https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXXXXX
```

Create webhooks: **Slack → App Directory → Incoming Webhooks**

### Step 3: Run Deployment Script

```bash
chmod +x deploy-aiops.sh
./deploy-aiops.sh
```

This script will:
- ✅ Verify all prerequisites (dtctl, curl)
- ✅ Create credentials in Dynatrace Credential Vault
- ✅ Deploy the workflow
- ✅ Display deployment summary

### Step 4: Validate Deployment

```bash
chmod +x validate-deployment.sh
./validate-deployment.sh
```

Validation checks:
- ✅ dtctl connectivity
- ✅ Dynatrace API token
- ✅ PagerDuty API token
- ✅ GitHub API token
- ✅ ArgoCD connectivity
- ✅ Slack webhooks
- ✅ Dynatrace credentials
- ✅ Workflow deployment status

---

## Post-Deployment Configuration

After running the scripts, complete these steps in Dynatrace UI:

### 1. Configure Workflow Trigger

1. Go to **Automation → Workflows**
2. Find: **EKS GitOps Auto-Remediation with PagerDuty & Observability Verification**
3. Click **"Change trigger"**
4. Select **Dynatrace problem** as trigger type
5. Filter for **Kubernetes pod failures**
6. Save

### 2. Add Remediation Tasks

Click **"Select + to add tasks"** and add:

1. **Extract Pod Metadata** - JavaScript to extract event data
2. **Create PagerDuty Incident** - HTTP request to PagerDuty API
3. **Query Dynatrace Pod Details** - API call for pod status
4. **Analyze Failure Type** - JavaScript to determine remediation
5. **Generate Remediation Plan** - Create YAML manifest
6. **Create Git Commit** - Push remediation to GitHub
7. **Trigger ArgoCD Sync** - Call ArgoCD webhook
8. **Wait for GitOps Sync** - Poll ArgoCD status
9. **Verify Remediation** - Check pod health metrics
10. **Resolve or Escalate** - Close incident or escalate

### 3. Test Workflow

Option A: **Manual Test**
- Click **"Run"** button on workflow
- Provide test pod name, namespace, cluster

Option B: **Trigger Real Event**
- Simulate pod failure in Kubernetes cluster
- Workflow will auto-execute when pod problem occurs

---

## Credentials in Vault

The deployment script creates these credentials in **Dynatrace Credential Vault**:

| Credential | Type | Used By |
|---|---|---|
| `dynatrace_api_token` | Token | Query pod details, metrics, logs |
| `argocd_api_token` | Token | Trigger GitOps sync |
| `github_token` | Token | Push remediation commits |
| `slack_webhook_incidents` | Token | Success notifications |
| `slack_webhook_critical` | Token | Escalation alerts |

**Note:** PagerDuty uses the existing Dynatrace connection (`PagerDuty-Production-Alerts`)

Access them in workflows with:
```javascript
{{ secrets('credential_name') }}
```

---

## Workflow Configuration Structure

```
Trigger: Dynatrace Problem (pod failure)
    ↓
Task 1: Extract Metadata (pod name, cluster, service)
    ↓
Task 2: Create PagerDuty Incident
    ↓ (parallel)
Task 3: Query Dynatrace Pod Details
    ↓
Task 4: Analyze Failure Type
    ↓
Task 5: Generate Remediation Plan
    ↓
Task 6: Create Git Commit
    ↓
Task 7: Trigger ArgoCD Sync
    ↓
Task 8: Wait for Sync Completion
    ↓
Task 9: Verify Remediation
    ↓
Task 10: Resolve Incident or Escalate
    ↓
Notify Slack (Success or Alert)
```

---

## Troubleshooting

### Script errors:

**"❌ ERROR: .env file not found!"**
```bash
cp .env.template .env
nano .env  # Add your credentials
```

**"❌ ERROR: dtctl not found"**
```bash
# Install dtctl first
brew install dynatrace/dynatrace-cli/dtdctl
# OR
# Download from: https://github.com/dynatrace-oss/dynatrace-cli
```

**"⚠️ Workflow may already exist"**
- The workflow was already deployed
- Run validation script to check status

### Validation failures:

**"❌ FAIL: Dynatrace API token is invalid"**
- Check token format: `dt0c01.XXXX.XXXX...`
- Verify token has `entities.read`, `logs.read`, `metrics.read` scopes
- Token may have expired

**"❌ FAIL: PagerDuty API token is invalid"**
- Verify API key is from PagerDuty (not OAuth token)
- Check service ID exists: `PAGERDUTY_SERVICE_ID`

**"❌ FAIL: GitHub API token is invalid"**
- Verify token scopes: `repo`, `workflow`
- Token format: `ghp_XXXX...`

**"❌ FAIL: ArgoCD is unreachable"**
- Check ArgoCD server URL is correct
- Verify ArgoCD is running: `kubectl get svc -n argocd`
- Check firewall/network access

**"❌ FAIL: Slack webhook is invalid"**
- Verify webhook URL format: `https://hooks.slack.com/services/...`
- Check webhook channel exists
- Bot must have permission to post

---

## Files Included

| File | Purpose |
|---|---|
| `.env.template` | Environment variable template |
| `deploy-aiops.sh` | Main deployment script |
| `validate-deployment.sh` | Validation script |
| `dynatrace-workflow-executable.json` | Workflow definition |
| `eks-gitops-auto-remediation-workflow.json` | Design reference |
| `DEPLOYMENT_GUIDE.md` | This file |

---

## Support

### Documentation References

- [Dynatrace Workflows](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows)
- [Credential Vault](https://docs.dynatrace.com/docs/manage/credential-vault)
- [PagerDuty API](https://developer.pagerduty.com/docs/rest-api-v2/getting-started/)
- [ArgoCD API](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_api/)
- [GitHub API](https://docs.github.com/en/rest)

### Useful Commands

```bash
# Check workflow status
dtctl get workflow e4bd6e5f-f19f-4d35-8e33-c4eb925d56b9

# View workflow history
dtctl history workflow e4bd6e5f-f19f-4d35-8e33-c4eb925d56b9

# List all workflows
dtctl get workflows

# View workflow execution logs
dtctl get executions --workflow=e4bd6e5f-f19f-4d35-8e33-c4eb925d56b9

# Test credentials
curl -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
  ${DYNATRACE_ENV_URL}/api/v2/entities?limit=1
```

---

## Organization Details

- **Organization:** nimishmehta8779
- **Workflow ID:** e4bd6e5f-f19f-4d35-8e33-c4eb925d56b9
- **Workflow Name:** EKS GitOps Auto-Remediation with PagerDuty & Observability Verification

---

## Next Steps After Deployment

1. ✅ **Credentials deployed** → All API tokens stored in Credential Vault
2. ✅ **Workflow deployed** → Workflow created in Dynatrace
3. ⏳ **Configure trigger** → Change from "On demand" to "Dynatrace problem"
4. ⏳ **Add tasks** → Implement remediation actions
5. ⏳ **Test workflow** → Simulate pod failure and verify
6. ⏳ **Monitor** → Watch execution logs and Slack notifications
7. ⏳ **Iterate** → Adjust remediation logic based on results

---

**Version:** 1.0  
**Last Updated:** 2026-07-03  
**Status:** ✅ Production Ready
