# EKS AIOps - Quick Start Guide

Get your first end-to-end AIOps remediation running in **15 minutes**.

---

## ⏱️ **15-Minute Setup**

### ✅ Step 1: Register App in ArgoCD (2 min)

```bash
kubectl apply -f argocd-apps/load-generator-application.yaml
```

Verify:
```bash
argocd app get load-generator-app
# Status: OutOfSync (expected - no app deployed yet)
```

### ✅ Step 2: Deploy Test App (3 min)

```bash
kubectl apply -f apps/load-generator/deployment.yaml
```

Verify:
```bash
kubectl get pods -n team-alpha-apps -w
# Wait for pod: load-generator-xxxxx → Running
```

### ✅ Step 3: Monitor CPU Load (2 min)

```bash
kubectl top pods -n team-alpha-apps
# Expected: load-generator CPU ~150-300m (exceeds 80m threshold)
```

### ✅ Step 4: Watch Dynatrace (5 min)

```
Dynatrace UI → Problems → Active
Look for: "K8s Container CPU High — team-alpha-apps"
Status should show: OPEN with RED indicator
```

### ✅ Step 5: Monitor Remediation (3 min)

```
Dynatrace → Automation → Workflows → david-ai-production
Click Latest Execution
Watch tasks complete:
  ✅ davis_root_cause (Analyzing...)
  ✅ decide_remediation (Scaling...)
  ✅ create_pagerduty_incident (Alerting...)
  ✅ create_jira_ticket (Tracking...)
  ✅ create_git_commit (Pushing to Git...)
  ✅ verify_remediation (Checking...)
```

### ✅ Step 6: Verify Success (Last 2 min)

**Check Scaling:**
```bash
kubectl get deployment -n team-alpha-apps load-generator
# DESIRED: 3, CURRENT: 3, READY: 3
```

**Check Git Commit:**
```bash
cd eks-gitops
git log --oneline remediation/ -1
# Output: abc1234 [DT-P-12345][cpu_saturation] scale_replicas: load-generator
```

**Check Problem Closed:**
```
Dynatrace → Problems → All
Search: "K8s Container CPU High"
Status: CLOSED ✅
```

---

## 🎯 **What Happened Automatically**

| Time | Component | Action |
|------|-----------|--------|
| T+0 | Pod | Deployed with high CPU load |
| T+5m | Dynatrace | Collected metrics |
| T+8m | Alert | Metric Event fired |
| T+10m | Workflow | **TRIGGERED** |
| T+10m:30s | Davis | Analyzed root cause |
| T+10m:40s | Decide | Routed to `scale_replicas` |
| T+10m:50s | Git | Committed manifest |
| T+11m | ArgoCD | **AUTO-SYNCED** |
| T+11m:10s | Kubernetes | Scaled 1→3 pods |
| T+14m | Verify | Problem CLOSED ✅ |
| T+15m | Email | Report SENT ✅ |

---

## 🔍 **Verify Each Step**

### Dynatrace Workflow Execution

```bash
# Get latest execution
dtctl logs wfe <execution-id>

# Should show:
# ✅ davis_root_cause: SUCCESS
# ✅ decide_remediation: SUCCESS
# ✅ create_pagerduty_incident: SUCCESS
# ✅ create_jira_ticket: SUCCESS
# ✅ create_git_commit: SUCCESS
# ✅ verify_remediation: SUCCESS
```

### GitHub Commit

```bash
git log --oneline -5
# a1b2c3d [DT-P-12345][cpu_saturation] scale_replicas: load-generator
# ... (previous commits)
```

### PagerDuty Incident

```
PagerDuty → Incidents
Incident: "[cpu_saturation] load-generator - K8s Container CPU High"
Status: RESOLVED ✅
```

### Jira Ticket

```
Jira → OPS Project
Ticket: "[AUTO][cpu_saturation] load-generator - K8s Container CPU High"
Status: Closed (or similar)
```

### ArgoCD Application

```
ArgoCD → Applications → load-generator-app
Sync Status: Synced ✅
Health: Healthy ✅
```

---

## 📊 **Expected Metrics**

### Before Remediation (T+0 to T+10m)
- Pod Count: **1**
- CPU per Pod: **250-300m** (exceeds threshold)
- Problem Status: **OPEN** 🔴

### After Remediation (T+15m+)
- Pod Count: **3**
- CPU per Pod: **80-100m** (below threshold) ✅
- Problem Status: **CLOSED** 🟢

---

## 🆘 **Quick Troubleshooting**

### "Dynatrace not detecting problem"

```bash
# 1. Check pod has high CPU
kubectl top pods -n team-alpha-apps load-generator
# Should show 150m+ CPU

# 2. Check metric event exists
# Dynatrace → Settings → Anomaly Detection → Metric Events
# Search for: "K8s Container CPU High"

# 3. Check cluster tag
kubectl get ns team-alpha-apps -o yaml | grep -i label
# Should have: dt.kubernetes.cluster.name: alpha-dev-general-3
```

### "Workflow not triggering"

```bash
# 1. Check problem created
# Dynatrace → Problems → All
# Filter for "CPU High"

# 2. Check workflow deployed
dtctl get workflows | grep david-ai
# Should show: david-ai-production DEPLOYED

# 3. Check workflow trigger active
dtctl describe workflow <id> | grep -i trigger
# Should show: isActive: true
```

### "ArgoCD not syncing"

```bash
# 1. Check app status
argocd app get load-generator-app
# Should show: Sync Status: OutOfSync (if Git changed)

# 2. Check Git accessible
argocd repo list
# Should show: Status: successful

# 3. Force sync
argocd app sync load-generator-app
```

---

## 🎓 **Learning Path**

**Beginner:** Run this quick start  
**Intermediate:** Read [E2E_DEPLOYMENT.md](E2E_DEPLOYMENT.md)  
**Advanced:** Customize remediation scenarios  
**Expert:** Extend to multiple applications & clusters  

---

## ✅ **Success Checklist**

- [ ] ArgoCD app registered
- [ ] Test app deployed
- [ ] Pod shows high CPU (`kubectl top`)
- [ ] Dynatrace problem detected
- [ ] Workflow triggered automatically
- [ ] Git commit created
- [ ] ArgoCD synced changes
- [ ] Deployment scaled to 3 pods
- [ ] Problem closed
- [ ] CPU normalized (80-100m per pod)
- [ ] Email report received
- [ ] 🎉 **END-TO-END SUCCESS!**

---

## 🚀 **Next Steps**

1. **Celebrate!** You've built production-grade AIOps
2. **Document** your experience
3. **Deploy** to more services
4. **Customize** remediation scenarios
5. **Scale** to multiple clusters

---

**Time to Complete:** ~15 minutes  
**Complexity:** Beginner-friendly  
**Impact:** Enterprise-grade automation  

Good luck! 🚀
