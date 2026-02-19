# GenAI for Software Testers - Training Environment

This repository contains two distinct projects for practicing Generative AI techniques in software testing. Each project is self-contained in its own directory.

## Available Projects

### 1. GenAI E-commerce Store (`ecommerce/`)
A B2C shopping application with product catalog, cart, checkout, wallet, and order management features.

- **Frontend**: [http://localhost:3000](http://localhost:3000)
- **API**: [http://localhost:8081](http://localhost:8081)
- **Database**: Postgres (5432)

**To Start:**
```bash
cd ecommerce
docker compose up -d --build
```

### 2. Upland Workflow App (`upland_workflow/`)
A B2B document intake and workflow application (Upland-themed). Features include document upload, AI extraction (mock), approval workflows, and audit logs.

- **Frontend**: [http://localhost:3002](http://localhost:3002)
- **API**: [http://localhost:8082](http://localhost:8082)
- **Database**: Postgres (5434)
- **Admin**: pgAdmin (5052)

**To Start:**
```bash
cd upland_workflow
./scripts/start.ps1
# OR manually:
docker compose up -d --build
```

## Running Multiple Projects

All projects now run on unique ports, so you can **run both simultaneously** if desired!

- **E-commerce**: Port 3000 (UI), 8081 (API)
- **Upland Workflow**: Port 3002 (UI), 8082 (API)

## Shared Resources

- **`playwright/`**: End-to-end tests (primarily configured for e-commerce, adaptable for workflow).
- **`postman/`**: API collections (check subfolders or import individually).
- **`performance/`**: Locust load test scripts.
- **`setup/`**: Installation scripts for Windows tools.

## Quick Troubleshooting

- **Port Conflicts**: If an app fails to start, check if the other one is running. Use `docker ps` to see active containers and `docker compose down` to stop them.
- **Database**: Both use Postgres on port 5432. The connection strings are pre-configured in their respective `docker-compose.yml` files.

