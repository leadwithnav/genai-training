# Upland Workflow Training App

A containerized "Document Intake & Workflow" application designed for software testing training.

## Architecture
- **Web UI**: Static HTML/JS served by Nginx (Port 3002)
- **API**: Node.js + Express (Port 8082)
- **Database**: PostgreSQL (Port 5434)
- **Admin**: pgAdmin (Port 5052)

## Quick Start
1. Ensure Docker Desktop is running.
2. Open PowerShell in this folder.
3. Run:
   ```powershell
   ./scripts/start.ps1
   ```

4. Access the App: http://localhost:3002

## API Endpoints
- `GET /api/documents` - List all documents
- `POST /api/documents` - Upload new document
- `GET /api/documents/:id` - Get document details
- `POST /api/documents/:id/approve` - Approve document
- `POST /api/documents/:id/reject` - Reject document
- `POST /api/documents/:id/deliver` - Deliver document

## Troubleshooting
- **Database Connection Error**: The API might start faster than the DB. It has a retry mechanism, so just wait a few seconds or run `./scripts/reset.ps1`.
