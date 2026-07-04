# EKS GitOps AIOps Auto-Remediation

Production-grade Kubernetes automation that detects problems via Dynatrace, analyzes root causes with AI, and automatically remediates issues through GitOps.

**Status:** ✅ Production Ready

---

## 🎯 **Overview**

This repository implements a **complete AIOps pipeline** for EKS clusters:

```
Dynatrace Problem Detection
    ↓
Davis AI Root Cause Analysis
    ↓
Intelligent Scenario Routing
    ↓
Automatic Remediation via GitOps
    ↓
Verification & Notification
    ↓
Auto-Closure of Incidents
```

---

## 📁 **Repository Structure**

```
eks-gitops/
├── apps/
│   └── load-generator/
│       └── deployment.yaml          # Test application (CPU stress)
├── argocd-apps/
│   └── load-generator-application.yaml  # ArgoCD app definition
├── remediation/
│   ├── load-generator/              # Auto-generated remediation manifests
│   ├── payment-service/             # Auto-generated remediation manifests
│   └── api-gateway/                 # Auto-generated remediation manifests
├── docs/
│   ├── E2E_DEPLOYMENT.md           # Step-by-step end-to-end guide
│   └── REMEDIATION_SCENARIOS.md    # Detailed scenario documentation
├── .env.template                    # Environment configuration template
├── deploy-aiops.sh                  # Deployment script
├── validate-deployment.sh           # Validation script
└── README.md                        # This file
```

---

## 🚀 **Quick Start**

### Prerequisites
- ✅ EKS Cluster: `alpha-dev-general-3`
- ✅ ArgoCD installed in `argocd` namespace
- ✅ Dynatrace monitoring deployed
- ✅ GitHub repository access
- ✅ kubectl configured

### Step 1: Register Application in ArgoCD

```bash
# Apply ArgoCD application definition
kubectl apply -f argocd-apps/load-generator-application.yaml

# Verify registration
argocd app get load-generator-app
```

### Step 2: Deploy Test Application

```bash
# Deploy load generator (triggers CPU saturation)
kubectl apply -f apps/load-generator/deployment.yaml

# Verify deployment
kubectl get pods -n team-alpha-apps
kubectl top pods -n team-alpha-apps  # Should show high CPU
```

### Step 3: Trigger Dynatrace Workflow

Dynatrace will automatically:
1. ✅ Detect CPU saturation alert
2. ✅ Create Davis problem
3. ✅ Trigger workflow execution
4. ✅ Analyze root cause (CPU)
5. ✅ Route to `scale_replicas` scenario
6. ✅ Create PagerDuty incident
7. ✅ Create Jira ticket
8. ✅ Commit remediation manifest to Git
9. ✅ ArgoCD auto-syncs changes
10. ✅ Scale deployment to 3 replicas
11. ✅ Verify problem closure
12. ✅ Send email report
13. ✅ Auto-resolve incident

---

## 📊 **Supported Remediation Scenarios**

### 1. **CPU Saturation** 
- **Trigger:** CPU usage exceeds 80 millicores
- **Action:** Scale deployment replicas to distribute load
- **File:** `remediation/<service>/scale_replicas.yaml`
- **Example:** 1 pod → 3 pods = load divided by 3

### 2. **Memory/OOM Issues**
- **Trigger:** Out of Memory (OOMKilled)
- **Action:** Increase memory limits
- **File:** `remediation/<service>/increase_memory.yaml`
- **Example:** 256Mi → 1Gi limit

### 3. **Pod Crashes**
- **Trigger:** CrashLoopBackOff detected
- **Action:** Delete pod (controller respawns)
- **File:** `remediation/<service>/pod_restart.yaml`
- **Type:** Kubernetes Job using kubectl

### 4. **Image Pull Failures**
- **Trigger:** ImagePullBackOff error
- **Action:** Manual review (registry/credentials issue)
- **Status:** No auto-remediation (escalates to team)

### 5. **High Error Rates**
- **Trigger:** Application returning 5xx errors
- **Action:** Manual review (likely bad deploy)
- **Status:** Suggests rollback (human approval)

### 6. **Node/Capacity Issues**
- **Trigger:** Disk pressure or node capacity
- **Action:** Manual review + capacity audit
- **Status:** Triggers capacity forecasting

---

## 🔧 **Remediation Manifest Format**

When Dynatrace workflow executes, it commits manifests like:

```yaml
# remediation/load-generator/2026-07-04T11-51-33-scale_replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-generator
  namespace: team-alpha-apps
  labels:
    remediation-action: scale-replicas
    incident: dt-P-12345
spec:
  replicas: 3  # Scaled from 1 → 3 automatically
```

**ArgoCD automatically:**
1. Detects new file in Git
2. Applies manifest to cluster
3. Scales deployment as specified

---

## 📈 **Expected Flow Timeline**

```
T+0m        Pod deployed (1 replica, high CPU)
T+5m        Dynatrace collects metrics
T+8m        Metric alert fires
T+10m       Davis problem created
T+10m:30s   Workflow starts
T+10m:50s   Git commit pushed
T+11m       ArgoCD syncs change
T+11m:10s   Pod scaled to 3 replicas
T+14m       Verification passes
T+15m       Email sent, incident resolved
```

---

## 🔍 **Monitoring & Verification**

### Dynatrace UI
```
Problems → Active
→ Look for: "K8s Container CPU High — team-alpha-apps"
→ Status should change from OPEN to CLOSED in ~5 minutes
```

### ArgoCD UI
```
Applications → load-generator-app
→ Sync Status should show: "Synced"
→ Application Health: "Healthy"
```

### GitHub
```
eks-gitops → remediation/load-generator/
→ New file: 2026-07-04T11-51-33-scale_replicas.yaml
→ Commit message: "[DT-P-12345][cpu_saturation] scale_replicas: load-generator"
```

### Kubernetes
```bash
kubectl get deployment -n team-alpha-apps load-generator
# DESIRED: 3, CURRENT: 3, READY: 3 (after remediation)

kubectl top pods -n team-alpha-apps
# CPU usage should drop ~3x (distributed across pods)
```

---

## 🔐 **Configuration**

### Environment Variables (`.env.template`)

```bash
# Dynatrace
DYNATRACE_ENV_ID=ter28835
DYNATRACE_API_TOKEN=your_api_token
DYNATRACE_CLUSTER_NAME=alpha-dev-general-3

# GitHub
GITHUB_TOKEN=your_github_token
GITHUB_OWNER=nimishmehta8779
GITHUB_REPO=eks-gitops

# PagerDuty
PAGERDUTY_CONNECTION_ID=your_connection_id
PAGERDUTY_SERVICE_ID=P5DXFI2
PAGERDUTY_EMAIL=your_email@company.com

# Jira
JIRA_CONNECTION_ID=your_connection_id
JIRA_PROJECT_KEY=OPS

# ArgoCD
ARGOCD_URL=http://argocd-server:80
ARGOCD_TOKEN=your_argocd_token
```

---

## 📝 **Workflows Involved**

### Dynatrace Workflow: `david-ai-production.yaml`

**Tasks:**
1. `davis_root_cause` - Fetch AI analysis
2. `decide_remediation` - Route to correct action
3. `create_pagerduty_incident` - Alert on-call
4. `create_jira_ticket` - Track issue
5. `create_git_commit` - Push remediation manifest
6. `verify_remediation` - Confirm fix worked
7. `send_email_summary` - Notify team

---

## 🧪 **Testing the Pipeline**

### Test 1: CPU Saturation (Recommended)
```bash
# Deploy load-generator
kubectl apply -f apps/load-generator/deployment.yaml

# Expected: Pod scales from 1 → 3 in ~10 minutes
# Verify: kubectl get deployment -n team-alpha-apps load-generator
```

### Test 2: Manual Scaling
```bash
# Apply scaling manifest manually
kubectl apply -f remediation/load-generator/scale_replicas.yaml

# Verify ArgoCD picks up change
argocd app get load-generator-app
```

---

## 🛠️ **Troubleshooting**

### Problem: Dynatrace Not Detecting
```bash
# Check pod CPU usage
kubectl top pods -n team-alpha-apps load-generator

# Verify Dynatrace metric event
Dynatrace → Settings → Anomaly Detection → Metric Events
# Look for: "K8s Container CPU High — team-alpha-apps"
```

### Problem: Workflow Not Triggering
```bash
# Check if problem was created
Dynatrace → Problems → All

# Check workflow deployed
dtctl get workflows | grep david-ai
```

### Problem: ArgoCD Not Syncing
```bash
# Check ArgoCD app status
argocd app get load-generator-app

# Check Git repo access
argocd repo list

# Force sync
argocd app sync load-generator-app
```

---

## 📚 **Documentation**

- **[E2E_DEPLOYMENT.md](docs/E2E_DEPLOYMENT.md)** - Complete step-by-step guide
- **[REMEDIATION_SCENARIOS.md](docs/REMEDIATION_SCENARIOS.md)** - Detailed scenario breakdown
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Configuration & setup

---

## ✅ **Success Criteria Checklist**

- [ ] Application deployed to `team-alpha-apps` namespace
- [ ] ArgoCD application registered and synced
- [ ] Dynatrace detects CPU saturation
- [ ] Workflow triggers automatically
- [ ] Git commit pushed with remediation manifest
- [ ] ArgoCD syncs remediation changes
- [ ] Deployment scaled to 3 replicas
- [ ] Problem closed in Dynatrace
- [ ] PagerDuty incident created and resolved
- [ ] Jira ticket created
- [ ] Email report sent
- [ ] Full end-to-end flow verified ✅

---

## 🎓 **Learning Outcomes**

After running this pipeline, you'll understand:

✅ How Dynatrace detects production problems  
✅ How Davis AI analyzes root causes  
✅ How to automate remediation decisions  
✅ How GitOps enforces infrastructure changes  
✅ How to implement self-healing systems  
✅ How to integrate multiple platforms (PD, Jira, GitHub, ArgoCD)  

---

## 🚀 **Production Readiness**

This implementation is **production-ready** and includes:

✅ Multi-scenario support (OOM, CPU, Crashes, ImagePull, etc.)  
✅ Native Dynatrace integrations (no custom APIs)  
✅ GitOps for full audit trail  
✅ Automated verification  
✅ Complete notification pipeline  
✅ Incident lifecycle management  
✅ Error handling & retries  
✅ Comprehensive logging  

---

## 📞 **Support**

For issues or questions:
1. Check troubleshooting section above
2. Review workflow execution logs in Dynatrace
3. Verify all integrations are configured
4. Check GitHub repository has correct structure

---

## 📄 **License**

Internal Use - Partior

---

**Last Updated:** 2026-07-04  
**Version:** 1.0  
**Status:** ✅ Production Ready

**Next Steps:**
1. ✅ Deploy test application
2. ✅ Wait for Dynatrace detection (~10 min)
3. ✅ Watch automatic remediation
4. ✅ Verify all success criteria
5. ✅ Deploy to additional services
