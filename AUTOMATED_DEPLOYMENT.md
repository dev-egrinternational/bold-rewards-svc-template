# Automated Deployment Guide

## 🚀 How Automated Deployment Works

When you push code to `main` branch, everything happens **automatically**:

```
Push to GitHub
    ↓
GitHub Actions triggers
    ↓
Run tests (lint, unit, e2e)
    ↓
Build Docker image (tag: git commit SHA)
    ↓
Push image to ECR
    ↓
Update Kubernetes manifests with new image
    ↓
Deploy to EKS
    ↓
Service available with internet access
```

**You never need to manually build/push Docker images or run kubectl!**

## ⚙️ One-Time Setup (Required Before First Deploy)

### Step 1: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these 5 secrets:

| Secret Name | Value | Where to Get It |
|------------|--------|-----------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key | IAM → Users → Create Access Key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key | IAM → Users → Create Access Key |
| `EKS_CLUSTER_REGION` | `us-east-2` | From your Terraform |
| `EKS_CLUSTER_NAME` | `bold-rewards-eks-dev` | From Terraform output |
| `ECR_REPOSITORY` | `bold-rewards-svc-rewards` | From Terraform 04-services |

**Get cluster name**:
```bash
cd bold-rewards-iac-aws/03-compute
terraform output cluster_name
```

**Get ECR repository**:
```bash
cd bold-rewards-iac-aws/04-services
terraform output  # or just use the module name
```

### Step 2: Grant IAM Permissions

The IAM user needs access to Kubernetes. Run this **once**:

```bash
# Update kubeconfig
aws eks update-kubeconfig --name bold-rewards-eks-dev --region us-east-2

# Edit aws-auth ConfigMap
kubectl edit configmap aws-auth -n kube-system
```

Add your IAM user under `mapUsers`:

```yaml
apiVersion: v1
data:
  mapUsers: |
    - userarn: arn:aws:iam::800444474190:user/github-actions-deployer
      username: github-actions-deployer
      groups:
        - system:masters
```

Replace `800444474190` with your AWS account ID and `github-actions-deployer` with your IAM username.

## ✅ That's It! Now It's Fully Automated

After setup, your workflow is:

### Normal Development Flow

```bash
# 1. Make changes to your code
vim src/app.service.ts

# 2. Commit and push
git add .
git commit -m "Add new feature"
git push origin main

# 3. That's it! GitHub Actions handles:
#    - Running tests
#    - Building Docker image
#    - Pushing to ECR
#    - Deploying to Kubernetes
#    - Load Balancer updates
```

### Monitor Deployment

**Watch GitHub Actions**:
1. Go to your repo → Actions tab
2. See the running workflow
3. Check logs if anything fails

**Check deployment status**:
```bash
# See pods
kubectl get pods

# See service and Load Balancer URL
kubectl get svc

# See logs
kubectl logs -f deployment/<deployment-name>
```

## 🎯 What Happens Automatically

### 1. Image Building (GitHub Actions)
- Uses git commit SHA as tag (e.g., `abc123def456`)
- Multi-stage build for smaller image size
- Cached layers for faster builds
- Pushed to private ECR repository

### 2. Kubernetes Update (GitHub Actions)
- Kustomize replaces `placeholder-image` with real ECR image
- Rolling update strategy (zero downtime)
- Old pods stay running until new pods are healthy
- Automatic rollback if deployment fails

### 3. Load Balancer (AWS LB Controller)
- Detects Service type: LoadBalancer
- Creates Network Load Balancer (first deploy only)
- Updates target IPs when pods change
- Health checks every 30 seconds on `/health`
- DNS automatically points to healthy pods

## 🔍 Checking Your Deployment

### Get Service URL

```bash
# Get Load Balancer DNS
kubectl get svc

# Output example:
# NAME                         TYPE           EXTERNAL-IP
# dev-bold-rewards-svc-*       LoadBalancer   a1b2c3...elb.amazonaws.com

# Test health
curl http://a1b2c3...elb.amazonaws.com/health

# Test your API
curl http://a1b2c3...elb.amazonaws.com/api
```

### Check Pod Status

```bash
# Get pods
kubectl get pods

# Should show:
# NAME                                 READY   STATUS    RESTARTS   AGE
# dev-bold-rewards-svc-*-xxxxx-yyyyy   1/1     Running   0          2m

# View logs
kubectl logs -f deployment/<deployment-name>
```

## 🐛 Troubleshooting

### Workflow Fails at "Build and Push"

**Cause**: Missing or invalid AWS credentials

**Fix**: 
1. Verify secrets are set in GitHub
2. Test credentials locally:
```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
aws ecr describe-repositories
```

### Workflow Fails at "Deploy to EKS"

**Cause**: IAM user not added to Kubernetes RBAC

**Fix**: Follow Step 2 in setup (edit aws-auth ConfigMap)

### Pod in `ImagePullBackOff`

**Cause**: This shouldn't happen with automated deployment, but if it does:

**Fix**: 
```bash
# Check if image exists
aws ecr describe-images --repository-name <repo-name>

# The workflow should have pushed it automatically
# If not, check workflow logs in GitHub Actions
```

### Pod in `CrashLoopBackOff`

**Cause**: Application error (check logs)

**Fix**:
```bash
# View logs
kubectl logs <pod-name>

# Common issues:
# - Missing dependencies (check package.json)
# - Missing environment variables
# - Port mismatch
# - Application crashes on startup

# Fix code and push again - it will redeploy automatically
```

### Load Balancer Stays `<pending>`

**Cause**: Load Balancer Controller issue or subnet tags

**Fix**:
```bash
# Check LB Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Subnets should already be tagged (done in Terraform)
# If not, check Terraform 01-foundations layer
```

## 🔄 Rollback

If something goes wrong:

```bash
# Rollback to previous version
kubectl rollout undo deployment/<deployment-name>

# Check rollout history
kubectl rollout history deployment/<deployment-name>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=2
```

Or just revert your git commit and push - it will redeploy the old version.

## 🎓 Best Practices

### 1. Use Feature Branches

```bash
# Don't push directly to main
git checkout -b feature/new-api

# Make changes, test locally
npm run test

# Push to feature branch
git push origin feature/new-api

# Create Pull Request on GitHub
# Tests run automatically on PR
# Merge to main after review
```

### 2. Monitor Deployments

Set up Slack/Discord notifications in GitHub Actions:

```yaml
- name: Notify Slack
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 3. Environment-Specific Configs

You already have `deploy/overlays/dev/` - create more:

```bash
# Staging
cp -r deploy/overlays/dev deploy/overlays/staging

# Production
cp -r deploy/overlays/dev deploy/overlays/prod
```

### 4. Semantic Versioning

Tag releases:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Modify workflow to deploy tags to production.

## 🚫 What NOT to Do

❌ **Don't manually build/push Docker images**
   - Let GitHub Actions handle it

❌ **Don't manually run `kubectl apply`**
   - Push to git instead

❌ **Don't commit secrets to git**
   - Use GitHub Secrets

❌ **Don't skip tests**
   - Fix them instead

❌ **Don't force push to main**
   - Use proper git workflow

## 📊 Monitoring

### CloudWatch Logs

Application logs automatically go to CloudWatch (if configured).

### Metrics

```bash
# Pod resource usage
kubectl top pods

# See deployment status
kubectl rollout status deployment/<deployment-name>
```

### Alerts

Set up CloudWatch alarms for:
- Pod restart count
- Failed health checks
- High CPU/memory usage
- Load Balancer errors

## 🎉 Summary

**Your deployment is now fully automated!**

1. ✅ Write code
2. ✅ Push to GitHub
3. ✅ Everything else happens automatically
4. ✅ Service available on internet

No manual Docker builds, no manual kubectl commands, no manual deployments!

Just focus on writing code, and the pipeline handles the rest. 🚀

