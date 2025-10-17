# AWS Load Balancer Guide for Kubernetes on Fargate

This guide explains how to properly configure internet access to your microservices using AWS Load Balancer Controller.

## 📋 Table of Contents

1. [Solution Overview](#solution-overview)
2. [Network Load Balancer (NLB)](#network-load-balancer-nlb)
3. [Application Load Balancer (ALB)](#application-load-balancer-alb)
4. [Which to Choose?](#which-to-choose)
5. [Usage Examples](#usage-examples)

## Solution Overview

AWS Load Balancer Controller supports two types of load balancers:

| Type | OSI Level | Best For | Cost |
|------|-----------|----------|------|
| **NLB** | Layer 4 (TCP/UDP) | TCP applications, high performance, static IPs | $$$ |
| **ALB** | Layer 7 (HTTP/HTTPS) | Web apps, APIs, path-based routing | $$ |

## Network Load Balancer (NLB)

### When to Use?

✅ Need maximum performance  
✅ TCP/UDP protocols (not just HTTP)  
✅ Need static IP addresses  
✅ Simple TCP proxying without routing logic

### Configuration (already applied in service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    # Type: external (new format for AWS LB Controller)
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    
    # Target type: ip (required for Fargate!)
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    
    # Scheme: internet-facing (internet access) or internal (VPC only)
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    
    # Health check settings
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/health"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: "http"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "30"
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3000
```

### Additional NLB Annotations

```yaml
# For internal load balancer (VPC only)
service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"

# Cross-zone load balancing (enabled by default, but can be disabled)
service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"

# Preserve client IP
service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: "preserve_client_ip.enabled=true"

# Specific subnets (if you need to specify particular subnets)
service.beta.kubernetes.io/aws-load-balancer-subnets: "subnet-xxx,subnet-yyy"
```

## Application Load Balancer (ALB)

### When to Use?

✅ HTTP/HTTPS applications  
✅ Need path-based routing (/api, /admin, /public)  
✅ Need SSL/TLS termination  
✅ WebSockets, HTTP/2, gRPC  
✅ Multiple services behind one Load Balancer (cost savings)

### Configuration (see ingress-example.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    # Scheme: internet-facing or internal
    alb.ingress.kubernetes.io/scheme: internet-facing
    
    # Target type: ip (required for Fargate!)
    alb.ingress.kubernetes.io/target-type: ip
    
    # Health check
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

### SSL/HTTPS Setup

```yaml
annotations:
  # ACM certificate
  alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-2:ACCOUNT:certificate/CERT_ID
  
  # Listen ports
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
  
  # HTTP -> HTTPS redirect
  alb.ingress.kubernetes.io/ssl-redirect: '443'
```

### Path-Based Routing

```yaml
spec:
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
          - path: /admin
            pathType: Prefix
            backend:
              service:
                name: admin-service
                port:
                  number: 80
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

## Which to Choose?

### Choose NLB if:
- Your service is not HTTP/HTTPS (e.g., gRPC, custom TCP)
- Need maximum performance
- Need static IP addresses
- Simple case: one service = one load balancer

### Choose ALB if:
- HTTP/HTTPS application
- Need URL path routing
- Need SSL/TLS
- Want to combine multiple services behind one load balancer (save ~$16/month per ALB)

## Usage Examples

### Example 1: Simple REST API (NLB)

Already configured in `service.yaml`:

```bash
# Deploy
kubectl apply -k deploy/overlays/dev

# Get external address
kubectl get svc bold-rewards-svc-template -n default
# Wait for EXTERNAL-IP to change from <pending> to actual address
```

### Example 2: REST API with SSL (ALB)

1. Create ACM certificate in AWS for your domain
2. Add `ingress-example.yaml` to `kustomization.yaml`:

```yaml
# deploy/base/kustomization.yaml
resources:
  - deployment.yaml
  - service.yaml
  - ingress-example.yaml  # Add this line
```

3. Update ingress-example.yaml with certificate ARN
4. Deploy:

```bash
kubectl apply -k deploy/overlays/dev
kubectl get ingress -n default
```

### Example 3: Multiple Services Behind One ALB

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /rewards
            pathType: Prefix
            backend:
              service:
                name: bold-rewards-svc-rewards
                port:
                  number: 80
          - path: /ocr
            pathType: Prefix
            backend:
              service:
                name: bold-rewards-svc-ocr
                port:
                  number: 80
```

## 🔧 Troubleshooting

### Load Balancer Not Created

```bash
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check events
kubectl describe service YOUR_SERVICE_NAME
kubectl describe ingress YOUR_INGRESS_NAME
```

### Service Stays in Pending State

```bash
# Verify:
# 1. AWS Load Balancer Controller is running
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# 2. Subnets are properly tagged (already done in Terraform)
# 3. IAM roles are configured (already done in Terraform)
```

### Ports and Health Checks

```yaml
# Make sure:
# 1. targetPort in Service matches container port
# 2. Health check path exists in your application
# 3. Health check returns HTTP 200
```

## 📚 Additional Resources

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [NLB Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/guide/service/annotations/)
- [ALB Ingress Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/guide/ingress/annotations/)

## 💡 Best Practices

1. **Use ALB for HTTP/HTTPS** - cheaper and more features
2. **Always configure health checks** - critical for proper operation
3. **Use HTTPS in production** - data security
4. **One ALB for multiple services** - cost savings
5. **Internal load balancers for microservices** - internal communication shouldn't go through the internet
