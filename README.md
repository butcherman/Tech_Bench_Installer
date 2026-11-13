# Tech Bench Installer

The Tech Bench Installer deploys a new Tech Bench instance using Docker Engine and Docker Compose on Debian or Ubuntu Linux.

It installs or reuses Docker, prepares the production Compose deployment and application environment, configures HTTPS, pulls the required images, and starts the Tech Bench services.

> **Testing status:** The installer workflow is implemented, but a clean Debian/Ubuntu virtual-machine installation test is still pending. Treat this installer as pre-release until that test is completed.

## What the installer deploys

The installer uses the production `docker-compose.yml` included in this repository. It deploys the Tech Bench application and its supporting services:

- Tech Bench application (PHP-FPM)
- NGINX web server
- Laravel Reverb
- Laravel Horizon
- Laravel scheduler
- MySQL database
- Redis
- Meilisearch
- Docker Sidecar manager and worker

Application data, database files, search indexes, Redis data, uploaded/storage files, Sidecar data, and TLS material are stored in Docker named volumes.

## Requirements

### Supported operating systems

- Debian
- Ubuntu

Debian/Ubuntu derivatives may be offered a chance to continue, but they are not officially supported.

### Supported CPU architectures

- `amd64`
- `arm64`

### Server and network requirements

Before installation:

1. Prepare a clean Linux server or virtual machine with a working internet connection.
2. Configure a stable hostname or DNS record for the server if you intend to use a publicly trusted certificate.
3. Allow inbound TCP ports **80** and **443** through the server firewall and any upstream firewall/router.
4. Ensure the server can resolve and reach external services, including Docker Hub and the Docker package repository.
5. Run the installer from an account with `sudo` access.

The installer does not configure your DNS records, firewall, router, or cloud security rules.

## Deploy a new Tech Bench instance

### 1. Download the installer

The current development installer branch is `dev9-installer`:

```bash
git clone --branch dev9-installer --single-branch https://github.com/butcherman/Tech_Bench_Installer.git
cd Tech_Bench_Installer
```

### 2. Run the installer

Run the script with root privileges:

```bash
sudo bash install.sh
```

The installer is interactive. It will perform system checks and then guide you through the following configuration.

### 3. Confirm the installation directory

The default installation directory is:

```text
/opt/tech-bench
```

You can accept the default or provide another absolute path.

The installer places the production Compose file and application `.env` file in this directory.

### 4. Configure the server hostname or IP address

When prompted, enter the hostname or IPv4 address that users will use to access Tech Bench.

Enter only the hostname or IP address. Do not include:

- `https://` or `http://`
- A port number
- A URL path

For example:

```text
techbench.example.com
```

For a publicly trusted Let's Encrypt certificate, use a public DNS hostname that resolves to this server. An IP address or private-only hostname should use the self-signed certificate option.

### 5. Select image versions

The installer asks for image tags for:

- Tech Bench application and NGINX images
- Tech Bench database image
- Docker Sidecar images

The default for each is `latest`. You may enter a specific tag when you need to deploy a particular release. The application and NGINX images share the same `APP_VERSION` tag.

For a production deployment, use image tags that have been published and verified for the Tech Bench release you intend to install.

### 6. Configure HTTPS

Choose one of the available certificate options.

#### Option A: Let's Encrypt

Choose this when the server has a public DNS hostname.

You will be asked for an email address for certificate expiry notifications. The installer uses Certbot's standalone HTTP challenge, so:

- The DNS hostname must resolve to this server.
- Inbound TCP port 80 must be reachable from the public internet while the certificate is issued or renewed.
- Port 443 must be reachable by users for normal HTTPS access.

The installer configures Certbot renewal hooks, enables the Certbot timer when available, copies the certificate into the NGINX keystore volume, and restarts NGINX after a renewed certificate is deployed.

#### Option B: Self-signed certificate

Choose this for private networks, IP-based access, or environments where a publicly trusted certificate is not appropriate.

The installer creates a self-signed certificate valid for 10 years and installs it in the NGINX keystore volume. Browsers and client devices will display a certificate warning until the certificate is explicitly trusted by those devices.

### 7. Wait for deployment

After HTTPS setup, the installer:

1. Validates the Docker Compose configuration.
2. Pulls the required container images.
3. Starts the services using Compose dependency ordering.
4. Waits up to 15 minutes for services to reach their configured running/healthy state.
5. Prints service status and recent logs if startup fails.

When deployment succeeds, the installer prints the Tech Bench HTTPS address.

Initial startup may take several minutes while images download and application services initialize.

## After installation

### Access Tech Bench

Open the HTTPS address displayed by the installer:

```text
https://your-hostname
```

For a self-signed certificate, accept or install the certificate trust as appropriate for your environment.

### Check service status

From the installation directory:

```bash
cd /opt/tech-bench
sudo docker compose --project-name tech-bench --env-file .env -f docker-compose.yml ps
```

If you selected a different installation directory or Compose project name, adjust the command accordingly.

### View service logs

View all service logs:

```bash
sudo docker compose --project-name tech-bench --env-file .env -f docker-compose.yml logs
```

Follow logs while troubleshooting:

```bash
sudo docker compose --project-name tech-bench --env-file .env -f docker-compose.yml logs -f
```

To view logs for one service, append its service name, for example:

```bash
sudo docker compose --project-name tech-bench --env-file .env -f docker-compose.yml logs -f tech_bench
```

### Important configuration and data files

| Location | Purpose |
|---|---|
| `/opt/tech-bench/.env` | Application settings, image tags, and generated secrets |
| `/opt/tech-bench/docker-compose.yml` | Production Docker Compose deployment |
| Docker named volumes | Persistent database, application, search, Redis, Sidecar, and TLS data |
| `/etc/letsencrypt` | Let's Encrypt certificates and renewal configuration, when selected |

The `.env` file contains passwords and application configuration. It is restricted to root access by the installer. Keep it private and include it in secure backups.

## Re-running the installer

The installer is designed to preserve existing configuration when run against an existing installation:

- An existing Compose file is left unchanged.
- Existing non-empty `.env` values are preserved.
- Existing generated secrets are not intentionally replaced.
- An existing TLS certificate is preserved unless you explicitly choose to replace it.
- Docker named volumes are not deleted by the installer.

Review any existing installation before running the installer again. If you intentionally want to change the Compose deployment, back up the current files and data first.

## Backups and maintenance

Back up the application `.env` file and all persistent Docker volumes. A backup that contains only the Compose file is not sufficient to restore an instance.

**Never use `docker compose down --volumes` (or `docker compose down -v`) as a routine troubleshooting command.** It removes the Compose project's named volumes and can permanently delete the database and application data.

Tech Bench application updates are intended to be handled through the Docker Sidecar / in-app update mechanism. The installer is for initial deployment and does not provide a separate scheduled update process.

## Troubleshooting

If installation fails:

1. Read the error message printed by the installer.
2. Check the service status and logs using the commands above.
3. Confirm that the server has internet/DNS access and sufficient disk space.
4. For Let's Encrypt failures, verify public DNS and inbound TCP port 80.
5. For browser connection failures, verify inbound TCP port 443 and the server's firewall rules.

The installer prints recent logs for all Compose services when image pulling or startup fails. Save that output when requesting support.

## Repository development status

The installer is being developed on the `dev9-installer` branch. It has not yet completed a clean-VM validation cycle. Do not treat a successful GitHub commit or code review as proof of a successful customer installation.
