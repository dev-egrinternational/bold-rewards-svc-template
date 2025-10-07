# Service: bold-rewards-svc-template

A NestJS-based microservice template for the BOLD Rewards platform.

## Local Development

1.  Install dependencies: `npm install`
2.  Create a `.env` file based on `.env.example` (if one exists).
3.  Start the application in development mode: `npm run start:dev`
4.  The service will be available at `http://localhost:3000`.

## Environment Variables

| Variable | Description | Required | Example |
| :--- | :--- | :--- | :--- |
| `PORT` | Port the service runs on | Yes | `3000` |
| `DATABASE_URL` | Database connection URL | Yes | `postgres://user:pass@host:port/db` |
| `TENANT_SVC_URL`| Tenant service URL | No | `http://tenant-svc.default.svc.cluster.local` |

## API Endpoints

-   `GET /health`: Health check endpoint.
-   `...`
