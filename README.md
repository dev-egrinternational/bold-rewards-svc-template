# BOLD Rewards Service: [YOUR_SERVICE_NAME]

This repository is a template for creating backend microservices for the BOLD Rewards platform. It is built with NestJS and is designed for automated deployment to AWS EKS.

## Table of Contents
- [Local Development](#local-development)
- [The Automated Workflow](#the-automated-workflow)
- [One-Time Setup](#one-time-setup)
- [Deployment & Verification](#deployment--verification)
- [Contributing](#contributing)

---

## Local Development

To run and test the service on your local machine:

1.  **Install dependencies:**
    ```bash
    npm install
    ```
2.  **Run the service:**
    ```bash
    npm run start:dev
    ```
The service will be available at `http://localhost:3000`.

---

## The Automated Workflow

This repository is configured for a fully automated, hands-off deployment process.

1.  **Develop:** You write your service's business logic.
2.  **Push:** You push your code to the `dev` or `qa` branch.
3.  **CI/CD Pipeline Runs:** A GitHub Action automatically triggers, which:
    *   Builds a Docker image of your application.
    *   Pushes the image to a private Amazon ECR repository.
    *   Deploys the new version to the corresponding EKS cluster.

**The result: you push code, and it gets deployed. No manual Docker or `kubectl` commands are needed.**

---

## One-Time Setup

Before the first deployment of a **new service**, you must give it a unique name. This requires replacing the placeholder `bold-rewards-svc-template` with your actual service name (e.g., `bold-rewards-svc-new-service`) in the following **four** files:

1.  `deploy/base/kustomization.yaml`:
    *   Change: `app: bold-rewards-svc-template` -> `app: bold-rewards-svc-[YOUR_SERVICE_NAME]`
2.  `deploy/base/deployment.yaml`:
    *   Change: `name: bold-rewards-svc-template` -> `name: bold-rewards-svc-[YOUR_SERVICE_NAME]`
3.  `deploy/base/service.yaml`:
    *   Change: `name: bold-rewards-svc-template` -> `name: bold-rewards-svc-[YOUR_SERVICE_NAME]`
4.  `deploy/overlays/dev/patch-deployment.yaml`:
    *   Change: `name: bold-rewards-svc-template` -> `name: bold-rewards-svc-[YOUR_SERVICE_NAME]`

After making these changes, commit them to your repository.

---

## Deployment & Verification

Deployment is triggered automatically by pushing to a deployment branch (`dev` or `qa`).

You can monitor the progress in the "Actions" tab of your GitHub repository. Once the pipeline succeeds, you can verify the deployment using `kubectl`.

**Useful Commands:**

-   **Check running pods:**
    ```bash
    kubectl get pods -l app=bold-rewards-svc-[YOUR_SERVICE_NAME]
    ```
-   **Check deployment status:**
    ```bash
    kubectl rollout status deployment/bold-rewards-svc-[YOUR_SERVICE_NAME]
    ```
-   **View logs:**
    ```bash
    kubectl logs -f deployment/bold-rewards-svc-[YOUR_SERVICE_NAME]
    ```
-   **Get Load Balancer URL (to access the service):**
    ```bash
    kubectl get svc bold-rewards-svc-[YOUR_SERVICE_NAME]
    ```

---

## Contributing

We welcome contributions! Please follow our contribution guidelines.

### Workflow

1.  **Fork the repository.**
2.  **Create a new branch** for your changes (e.g., `feature/add-new-endpoint`).
3.  **Make your changes** and commit them using the Conventional Commits standard.
4.  **Push your changes** to your fork.
5.  **Create a Pull Request** to the main repository.

### Commit Message Style (Conventional Commits)

We use the [Conventional Commits](https://www.conventionalcommits.org/) standard.

**Format:** `<type>(<scope>): <description>`

-   **Main types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
-   **Example:** `feat(api): add user profile endpoint`