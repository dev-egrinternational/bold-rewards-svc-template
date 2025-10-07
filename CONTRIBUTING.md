# Contribution Guide

## Workflow

1.  **Fork the repository.**
2.  **Clone the fork** to your local machine: `git clone https://github.com/YOUR_USERNAME/bold-rewards-svc-template.git`
3.  **Create a new branch** for your changes.
4.  **Make your changes** and commit them.
5.  **Push your changes** to your fork: `git push origin feature/your-feature`
6.  **Create a Pull Request** to the main repository.

## Branch Naming

Use prefixes for branch names to clarify the type of changes they contain:

-   `feature/<short-description>`: for new functionality (e.g., `feature/user-authentication`).
-   `bugfix/<short-description>`: for bug fixes (e.g., `bugfix/fix-login-button`).
-   `chore/<short-description>`: for tasks not related to code (updating documentation, CI/CD setup).

## Commits

### Atomic Commits

A single commit should contain a single logical change. This helps in tracking changes and makes it easy to revert a commit if necessary.

### Commit Message Style (Conventional Commits)

We use the [Conventional Commits](https://www.conventionalcommits.org/) standard. This allows for automatic generation of changelogs and makes the commit history readable.

**Format:** `<type>(<scope>): <description>`

-   `<type>`: The type of change.
-   `<scope>` (optional): The scope of the change (e.g., `api`, `db`, `ui`).
-   `<description>`: A short description of the change in lowercase, without a period at the end.

**Main types:**

-   **feat**: a new feature.
-   **fix**: a bug fix.
-   **docs**: changes to documentation.
-   **style**: formatting, fixing typos, missing semicolons, etc. (without changing the code).
-   **refactor**: code refactoring without changing its behavior.
-   **test**: adding or fixing tests.
-   **chore**: routine tasks, builds, dependency management.

**Examples:**

-   `feat: add password hashing on user registration`
-   `fix(api): correct user validation logic`
-   `docs: update README with setup instructions`
-   `chore: add eslint configuration`

## Pull Request (PR)

When your work in a branch is complete, create a Pull Request to merge your branch into `main`.

-   **The PR title** should be informative and follow the Conventional Commits style.
-   **In the PR description**, briefly describe the changes made. If the PR closes an issue, specify its number (e.g., `Closes #123`).
-   Ensure that all tests and CI/CD checks pass successfully.