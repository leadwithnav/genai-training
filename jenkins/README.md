# Jenkins Setup (Docker Compose)

## Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

## Installation Steps

### 1. Start Jenkins
```bash
cd jenkins
docker-compose up -d --build
```

### 2. Wait for Jenkins to initialize
It takes ~1-2 minutes on first start while plugins install. Check logs:
```bash
docker-compose logs -f jenkins
```

### 3. Access Jenkins
Open **http://localhost:8080** in your browser.

> The setup wizard is disabled. Jenkins starts ready to use with pre-installed plugins.

### 4. Get the initial admin password (if needed)
If the setup wizard is enabled or you need the password:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Stopping Jenkins
```bash
docker-compose down
```

To also remove the persistent volume (wipes all Jenkins data):
```bash
docker-compose down -v
```

## Pre-installed Plugins
| Plugin | Purpose |
|---|---|
| workflow-aggregator | Pipeline support |
| git | Git SCM integration |
| github | GitHub integration |
| credentials-binding | Secure credentials in builds |
| pipeline-stage-view | Pipeline visualization |
| blueocean | Modern Jenkins UI |
| docker-workflow | Docker steps in pipelines |
| nodejs | Node.js build tool |

## Customization
- Edit [plugins.txt](plugins.txt) to add/remove plugins, then rebuild:
  ```bash
  docker-compose up -d --build
  ```
- Jenkins data persists in the `jenkins_home` Docker volume across restarts.
