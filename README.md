# BOLD Rewards Microservice Template (NestJS)

This repository is a template for creating backend microservices for the BOLD Rewards platform.

---

## Step 0: Creating Your Service Repository

1.  **Navigate to this template repository** on GitHub.
2.  Click the green **"Use this template"** button and select **"Create a new repository"**.
3.  Name your new repository** according to the service you are building (e.g., `bold-rewards-svc-user-profile`, `bold-rewards-svc-products`).
4.  **Clone your new repository** to your local machine. Now you are ready for the one-time setup.

---

## The Automated Workflow

This template is designed for a hands-off deployment process:

1.  **Develop:** You write your service's business logic and push your code to the `main` branch.
2.  **CI/CD Pipeline Runs:** A GitHub Action automatically triggers.
    *   It runs all tests to ensure code quality.
    *   It builds a Docker image of your application.
    *   It pushes the image to your private Amazon ECR repository.
    *   It updates the Kubernetes deployment configuration with the new image.
    *   It applies the changes to your EKS cluster, deploying the new version of your service.

**The result: you push code, and it gets deployed. No manual Docker or `kubectl` commands are needed.**

---

## Getting Started: One-Time Setup

Before you can use the automated workflow, a few things need to be configured once.

### 1. Infrastructure Prerequisites

*   **Core AWS Infrastructure:** The core infrastructure from the `bold-rewards-iac-aws` repository must be deployed (at least up to the `03-compute` layer to have an EKS cluster).
*   **Amazon ECR Repository:** Your service needs a dedicated ECR repository. This is created automatically using Terraform in the `bold-rewards-iac-aws` repository. Before proceeding, please follow the instructions in that repository's `README.md` (in the "Step 3: Provisioning Resources for a New Microservice" section) to create the ECR repository for your service.

### 2. GitHub Secrets

Navigate to your new repository's settings on GitHub: `Settings` > `Secrets and variables` > `Actions`.

Here, you must create secrets under the **Repository secrets** section. The CI/CD pipeline uses these to securely connect to your AWS account.

*   `AWS_ACCESS_KEY_ID`: Your AWS access key.
*   `AWS_SECRET_ACCESS_KEY`: Your AWS secret key.
*   `ECR_REPOSITORY`: The name of the ECR repository you created via Terraform (e.g., `bold-rewards-svc-rewards`).
*   `EKS_CLUSTER_REGION`: The AWS region where your EKS cluster is located (e.g., `us-east-2`).
*   `EKS_CLUSTER_NAME`: The name of your EKS cluster. For the `dev` environment, this is `bold-rewards-eks-dev`.

### 3. Service Configuration

Before your first deployment, you must give your service a unique name. This requires replacing the placeholder `bold-rewards-svc-template` with your actual service name (e.g., `bold-rewards-svc-rewards`) in the following **four** files:

1.  `deploy/base/kustomization.yaml`
    *   **Change:** `app: bold-rewards-svc-template` -> `app: bold-rewards-svc-[YOUR_SERVICE_NAME]`

2.  `deploy/base/deployment.yaml`
    *   **Change:** `name: bold-rewards-svc-template` -> `name: bold-rewards-svc-[YOUR_SERVICE_NAME]`

3.  `deploy/base/service.yaml`
    *   **Change:** `name: bold-rewards-svc-template` -> `name: bold-rewards-svc-[YOUR_SERVICE_NAME]`

4.  `deploy/overlays/dev/patch-deployment.yaml`
    *   **Change:** `name: bold-rewards-svc-template` -> `name: bold-rewards-svc-[YOUR_SERVICE_NAME]`

After making these changes, commit and push them to your `main` branch to trigger the first deployment.

## Local Development

While deployment is automated, you will still develop and test on your local machine.

1.  **Install dependencies:**
    ```bash
    npm install
    ```
2.  **Run the service locally:**
    ```bash
    npm run start:dev
    ```
3.  The service will be available at `http://localhost:3000`.

## Verifying Deployment

After you push to `main`, you can watch the progress in the "Actions" tab of your GitHub repository. Once the pipeline succeeds, you can verify the deployment in AWS or via `kubectl` if you have it configured locally.

*   **Check running pods:**
    ```bash
    kubectl get pods
    ```
*   **Access your service (for testing):**
    ```bash
    kubectl port-forward service/your-service-name 8080:3000
    ```
    Your service will be accessible at `http://localhost:8080`.