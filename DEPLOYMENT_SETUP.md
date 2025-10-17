# Deployment Setup Guide

This guide explains how to set up automatic deployment to AWS EKS using GitHub Actions.

## 🎯 How It Works "Out of the Box"

### What Happens When You Push to `main`:

1. **GitHub Actions triggers** automatically
2. **Tests run** (lint, unit tests, e2e tests)
3. **Docker image is built** with git commit SHA as tag
4. **Image is pushed** to Amazon ECR
5. **Kubernetes deployment updates** automatically
6. **AWS Load Balancer Controller** creates Network Load Balancer
7. **Service becomes accessible** from the internet via NLB

### Architecture Flow:

```
GitHub Push (main branch)
    ↓
GitHub Actions
    ↓
Docker Build → Push to ECR
    ↓
Update Kubernetes Manifests
    ↓
Deploy to EKS (Fargate)
    ↓
AWS Load Balancer Controller
    ↓
Network Load Balancer Created
    ↓
Internet Access via NLB DNS
```

## 🔧 One-Time Setup Required

Before the pipeline works, you need to configure GitHub Secrets.

### Step 1: Get AWS Credentials

You need an IAM user with the following permissions:
- ECR: Push/Pull images
- EKS: Describe cluster, update kubeconfig
- Kubernetes: Deploy resources

**Create IAM User** (if not exists):

```bash
# This should be done by someone with admin access
aws iam create-user --user-name github-actions-deployer
aws iam attach-user-policy --user-name github-actions-deployer --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

**Get Access Keys**:

```bash
aws iam create-access-key --user-name github-actions-deployer
```

Save the `AccessKeyId` and `SecretAccessKey`.

### Step 2: Get Infrastructure Details

From your Terraform outputs:

```bash
cd bold-rewards-iac-aws/03-compute
terraform output

# You'll need:
# - cluster_name (e.g., bold-rewards-eks-dev)
# - AWS region (us-east-2)

cd ../04-services
terraform output

# You'll need:
# - ECR repository name (bold-rewards-svc-template or bold-rewards-svc-rewards)
```

### Step 3: Configure GitHub Secrets

Go to your GitHub repository:
1. Click **Settings**
2. Click **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add these secrets:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `AWS_ACCESS_KEY_ID` | From Step 1 | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | From Step 1 | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `EKS_CLUSTER_REGION` | AWS Region | `us-east-2` |
| `EKS_CLUSTER_NAME` | Cluster name | `bold-rewards-eks-dev` |
| `ECR_REPOSITORY` | Repository name | `bold-rewards-svc-template` |

### Step 4: Verify IAM Permissions

The IAM user needs these additional permissions to deploy to EKS:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    }
  ]
}
```

**And** the user must be added to the Kubernetes RBAC:

```bash
# On your local machine with admin access to EKS
aws eks update-kubeconfig --name bold-rewards-eks-dev --region us-east-2

# Edit aws-auth ConfigMap
kubectl edit configmap aws-auth -n kube-system

# Add this under mapUsers:
# mapUsers: |
#   - userarn: arn:aws:iam::ACCOUNT_ID:user/github-actions-deployer
#     username: github-actions-deployer
#     groups:
#       - system:masters
```

## 🚀 Testing the Deployment

### Option 1: Push to Main

```bash
git add .
git commit -m "Test deployment"
git push origin main
```

Watch the GitHub Actions tab to see the pipeline run.

### Option 2: Manual kubectl Deploy

```bash
# Build and push Docker image
docker build -t $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-2.amazonaws.com/bold-rewards-svc-template:latest .
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-2.amazonaws.com/bold-rewards-svc-template:latest

# Deploy to Kubernetes
kubectl apply -k deploy/overlays/dev

# Watch deployment
kubectl get pods -w

# Get external access
kubectl get svc
```

## 🌐 Accessing Your Service

After deployment completes (2-3 minutes):

```bash
# Get the Load Balancer URL
kubectl get svc

# Example output:
# NAME                           TYPE           EXTERNAL-IP
# bold-rewards-svc-template      LoadBalancer   a1b2c3...elb.amazonaws.com

# Test the service
curl http://a1b2c3...elb.amazonaws.com/health
```

## 🔄 What Happens on Each Deploy

1. **Image Tag**: Uses git commit SHA (e.g., `abc123def456`)
2. **Zero Downtime**: Rolling update strategy
3. **Health Checks**: Load Balancer checks `/health` endpoint
4. **Auto Rollback**: If health checks fail, Kubernetes keeps old version running

## 📊 Monitoring Deployment

```bash
# Watch pods
kubectl get pods -l app=bold-rewards-svc-template -w

# Check deployment status
kubectl rollout status deployment/bold-rewards-svc-template

# View logs
kubectl logs -f deployment/bold-rewards-svc-template

# Check Load Balancer creation
kubectl describe svc bold-rewards-svc-template

# AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## 🐛 Troubleshooting

### Pipeline Fails at "Login to Amazon ECR"

**Problem**: AWS credentials are invalid or missing ECR permissions.

**Solution**: 
```bash
# Test credentials locally
aws ecr get-login-password --region us-east-2

# Verify IAM permissions
aws iam list-attached-user-policies --user-name github-actions-deployer
```

### Pipeline Fails at "Deploy to EKS"

**Problem**: IAM user doesn't have Kubernetes RBAC permissions.

**Solution**: Follow Step 4 above to add user to aws-auth ConfigMap.

### Load Balancer Not Created

**Problem**: AWS Load Balancer Controller not working or annotations wrong.

**Solution**:
```bash
# Check controller is running
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check service annotations
kubectl describe svc bold-rewards-svc-template

# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Health Checks Failing

**Problem**: Your app doesn't have `/health` endpoint or returns non-200 status.

**Solution**:
1. Make sure your NestJS app has a health check endpoint
2. Or change annotation in `service.yaml`:
```yaml
service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/api/health"
```

## 🎓 Best Practices

1. **Always tag images with commit SHA** - easier to track what's deployed
2. **Use Pull Request** deployments - test before merging to main
3. **Monitor logs** after deployment - catch issues early
4. **Set up alerts** - know when deployments fail
5. **Use environment-specific overlays** - dev, staging, prod

## 🔐 Security Notes

- **Never commit AWS credentials** to git
- **Use IAM roles** instead of access keys when possible (GitHub Actions supports OIDC)
- **Rotate access keys** regularly
- **Use least privilege** - don't give admin access if not needed
- **Enable MFA** on AWS accounts

## 📚 Next Steps

1. Set up **staging environment** (duplicate overlays/dev to overlays/staging)
2. Add **Slack/Discord notifications** to GitHub Actions
3. Set up **monitoring** (Prometheus/Grafana)
4. Add **SSL certificate** (use ALB instead of NLB with ACM)
5. Configure **custom domain** (Route 53)

