# BOLD Rewards Microservice Template (NestJS)

This repository is a template for creating backend microservices for the BOLD Rewards platform. It includes a pre-configured NestJS application, Dockerfile for containerization, and Kubernetes manifests for deployment.

## Flow: From Code to Cloud

The development lifecycle for a new microservice is as follows:

1.  **Scaffold:** Create a new repository from this template.
2.  **Develop:** Write your service's business logic.
3.  **Containerize:** Build a Docker image.
4.  **Publish:** Push the image to a container registry (Amazon ECR).
5.  **Deploy:** Apply Kubernetes manifests to the EKS cluster to run your service.

---

## Step-by-Step Deployment Guide

### Prerequisites

Before you begin, ensure you have the following:

1.  **Deployed AWS Infrastructure:** The core infrastructure from the `bold-rewards-iac-aws` repository must be deployed (at least up to the `03-compute` layer).
2.  **AWS CLI:** Installed and configured with credentials.
3.  **kubectl:** Installed and configured to connect to your EKS cluster. You can do this by running:
    ```bash
    aws eks update-kubeconfig --region [YOUR_AWS_REGION] --name [YOUR_EKS_CLUSTER_NAME]
    ```
4.  **Docker:** Installed and running on your local machine.
5.  **An Amazon ECR Repository:** You need a place to store your Docker images. Create one in the AWS console.
    *   Go to the Amazon ECR service.
    *   Click "Create repository".
    *   Choose "Private" and give it a name that matches your service (e.g., `my-new-service`).

### Step 1: Create Your Service Repository

1.  Click the "Use this template" button on the GitHub page for this repository.
2.  Choose "Create a new repository".
3.  Name your new repository (e.g., `user-profile-svc`) and create it.
4.  Clone your new repository to your local machine.

### Step 2: Local Development

1.  **Install dependencies:**
    ```bash
    npm install
    ```
2.  **Run the service locally:**
    ```bash
    npm run start:dev
    ```
3.  The service will be available at `http://localhost:3000`. You can now develop your business logic and API endpoints.

### Step 3: Configure for Deployment

The Kubernetes manifests are in the `deploy/` directory and use Kustomize for environment-specific configurations.

1.  **Update Application Name:**
    *   In `deploy/base/kustomization.yaml`, change `app: bold-rewards-svc-template` to `app: [YOUR_SERVICE_NAME]` (e.g., `app: user-profile-svc`).
    *   In `deploy/base/deployment.yaml`, update the `name` metadata to your service name.

2.  **Configure Environment Variables:**
    *   Open `deploy/overlays/dev/config.yaml`.
    *   This file holds your service's environment variables. Add or modify them as needed (e.g., `DATABASE_URL`).

### Step 4: Build and Push the Docker Image

1.  **Log in to Amazon ECR:**
    ```bash
    aws ecr get-login-password --region [YOUR_AWS_REGION] | docker login --username AWS --password-stdin [YOUR_AWS_ACCOUNT_ID].dkr.ecr.[YOUR_AWS_REGION].amazonaws.com
    ```

2.  **Build the Docker image:** Replace `[YOUR_SERVICE_NAME]` with your service's name (e.g., `user-profile-svc`).
    ```bash
    docker build -t [YOUR_SERVICE_NAME]:latest .
    ```

3.  **Tag the image for ECR:**
    ```bash
    docker tag [YOUR_SERVICE_NAME]:latest [YOUR_AWS_ACCOUNT_ID].dkr.ecr.[YOUR_AWS_REGION].amazonaws.com/[YOUR_ECR_REPO_NAME]:latest
    ```

4.  **Push the image to ECR:**
    ```bash
    docker push [YOUR_AWS_ACCOUNT_ID].dkr.ecr.[YOUR_AWS_REGION].amazonaws.com/[YOUR_ECR_REPO_NAME]:latest
    ```

### Step 5: Update the Deployment Image

1.  Open `deploy/overlays/dev/patch-deployment.yaml`.
2.  Find the `spec.template.spec.containers[0].image` line.
3.  Replace the placeholder image with the full URI of the image you just pushed to ECR:
    ```yaml
    # before
    image: your-registry/bold-rewards-svc-template:latest
    # after
    image: [YOUR_AWS_ACCOUNT_ID].dkr.ecr.[YOUR_AWS_REGION].amazonaws.com/[YOUR_ECR_REPO_NAME]:latest
    ```

### Step 6: Deploy to Kubernetes

Apply the Kubernetes configuration to your EKS cluster:

```bash
kubectl apply -k deploy/overlays/dev
```

This command tells Kubernetes to find your image in ECR and run it on the Fargate infrastructure.

### Step 7: Verify the Deployment

1.  **Check if the pod is running:**
    ```bash
    # Look for a pod with your service's name
    kubectl get pods
    ```
    The status should change from `Pending` to `ContainerCreating` to `Running`.

2.  **Check the service:**
    ```bash
    kubectl get service
    ```
    You should see a service for your application.

3.  **Access your service:**
    The service is now running inside the cluster. To access it from your local machine for testing, you can use port-forwarding:
    ```bash
    # kubectl port-forward service/[YOUR_SERVICE_NAME] [LOCAL_PORT]:[SERVICE_PORT]
    kubectl port-forward service/user-profile-svc 8080:3000
    ```
    You can now access your service at `http://localhost:8080`.
