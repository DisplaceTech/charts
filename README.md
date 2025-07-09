# WordPress Helm Charts

This repository contains Helm charts for deploying WordPress on Kubernetes with enterprise-grade features including object caching, full-page caching, automated backups, and immutable filesystem security.

## Features

- **Custom WordPress Image**: Built on `php:8.4-apache-bookworm` with pre-installed themes and plugins
- **Redis Object Caching**: Sidecar Redis container for improved performance
- **Batcache Full-Page Caching**: Server-side page caching for optimal performance
- **Custom Theme & Plugins**: Powder theme and Simple SEO plugin pre-installed and activated
- **Immutable Filesystem**: Enhanced security with read-only filesystem
- **Persistent Storage**: PVC-backed uploads and database directories
- **Automated Backups**: Weekly cronjobs for uploads and database backups to S3-compatible storage
- **Kubernetes Secrets Integration**: Secure credential management
- **Configurable Namespace**: Defaults to `wordpress` namespace

## Quick Start

### Prerequisites

- Kubernetes cluster (1.20+)
- Helm 3.x
- kubectl configured
- Access to GitHub Container Registry (GHCR)

### Basic Installation

```bash
# Add the repository
helm repo add wordpress-charts https://displacetech.github.io/charts

# Install WordPress
helm install my-wordpress wordpress-charts/wordpress

# Or install with custom namespace
helm install my-wordpress wordpress-charts/wordpress --namespace my-wordpress --create-namespace
```

### Advanced Installation with Custom Values

```bash
helm install my-wordpress wordpress-charts/wordpress \
  --namespace wordpress \
  --create-namespace \
  --values custom-values.yaml
```

## Configuration

### Required Secrets

Create the following Kubernetes secrets before deployment:

#### WordPress Secrets
```bash
kubectl create secret generic wordpress-secrets \
  --from-literal=db-name=wordpress \
  --from-literal=db-user=wordpress \
  --from-literal=db-password=your-secure-password \
  --from-literal=db-host=mysql \
  --from-literal=wp-auth-key=your-auth-key \
  --from-literal=wp-secure-auth-key=your-secure-auth-key \
  --from-literal=wp-logged-in-key=your-logged-in-key \
  --from-literal=wp-nonce-key=your-nonce-key \
  --from-literal=wp-auth-salt=your-auth-salt \
  --from-literal=wp-secure-auth-salt=your-secure-auth-salt \
  --from-literal=wp-logged-in-salt=your-logged-in-salt \
  --from-literal=wp-nonce-salt=your-nonce-salt \
  --from-literal=wp-admin-email=admin@example.com \
  --from-literal=wp-admin-password=your-admin-password
```

#### MySQL Secrets
```bash
kubectl create secret generic mysql-secrets \
  --from-literal=mysql-root-password=your-root-password \
  --from-literal=mysql-database=wordpress \
  --from-literal=mysql-user=wordpress \
  --from-literal=mysql-password=your-secure-password
```

#### Backup Secrets (Optional)
```bash
kubectl create secret generic backup-secrets \
  --from-literal=s3-endpoint=your-s3-endpoint \
  --from-literal=s3-access-key=your-access-key \
  --from-literal=s3-secret-key=your-secret-key \
  --from-literal=s3-bucket=your-backup-bucket \
  --from-literal=s3-region=your-region
```

### Values Configuration

Create a `custom-values.yaml` file:

```yaml
# WordPress Configuration
wordpress:
  image:
    repository: ghcr.io/your-username/wordpress
    tag: "latest"
    pullPolicy: Always
  
  # Resource limits
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  
  # Environment variables
  env:
    WP_DEBUG: "false"
    WP_CACHE: "true"
    REDIS_HOST: "localhost"
    REDIS_PORT: "6379"

# MySQL Configuration
mysql:
  enabled: true
  image:
    repository: mysql
    tag: "8.0"
  
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  
  persistence:
    size: 10Gi
    storageClass: ""

# Redis Configuration
redis:
  enabled: true
  image:
    repository: redis
    tag: "7-alpine"
  
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "128Mi"
      cpu: "100m"

# Backup Configuration
backups:
  enabled: true
  
  uploads:
    schedule: "0 2 * * 0"  # Weekly at 2 AM Sunday
    retention: 30  # Keep backups for 30 days
  
  database:
    schedule: "0 3 * * 0"  # Weekly at 3 AM Sunday
    retention: 30  # Keep backups for 30 days

# Ingress Configuration
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: wordpress.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wordpress-tls
      hosts:
        - wordpress.example.com

# Service Configuration
service:
  type: ClusterIP
  port: 80

# Persistence Configuration
persistence:
  uploads:
    size: 5Gi
    storageClass: ""
  database:
    size: 10Gi
    storageClass: ""

# Security Configuration
security:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

## Custom Image Development

### Building Your Own Image

The base image includes:
- WordPress 6.8.1
- PHP 8.4.10
- Apache with mod_rewrite
- Redis Object Cache plugin
- Batcache for full-page caching
- Powder theme
- Simple SEO plugin

To build your own custom image:

1. Clone this repository
2. Navigate to the `containers/` directory
3. Modify the Dockerfile to add your custom themes/plugins
4. Build and push to your registry

```bash
# Build locally
make build-image

# Build and push to GHCR
make build-and-push-image
```

### Adding Custom Themes/Plugins

Create a custom Dockerfile:

```dockerfile
FROM ghcr.io/your-username/wordpress:latest

# Add your custom themes
COPY themes/my-theme /var/www/html/wp-content/themes/my-theme/

# Add your custom plugins
COPY plugins/my-plugin /var/www/html/wp-content/plugins/my-plugin/

# Set permissions
RUN chown -R www-data:www-data /var/www/html/wp-content/themes/my-theme \
    && chown -R www-data:www-data /var/www/html/wp-content/plugins/my-plugin
```

## Backup Configuration

### S3-Compatible Storage Setup

The backup system supports any S3-compatible storage:
- AWS S3
- MinIO
- DigitalOcean Spaces
- Backblaze B2
- etc.

### Backup Retention

Backups are automatically cleaned up based on the retention period:
- Default: 30 days
- Configurable via `backups.uploads.retention` and `backups.database.retention`

### Manual Backup Trigger

```bash
# Trigger uploads backup
kubectl create job --from=cronjob/wordpress-uploads-backup manual-uploads-backup

# Trigger database backup
kubectl create job --from=cronjob/wordpress-database-backup manual-database-backup
```

## Monitoring and Logging

### Health Checks

The deployment includes:
- Liveness probe on `/wp-admin/admin-ajax.php`
- Readiness probe on `/wp-admin/admin-ajax.php`
- Startup probe with extended timeout

### Logging

Logs are available via:
```bash
# WordPress logs
kubectl logs -f deployment/wordpress

# MySQL logs
kubectl logs -f deployment/mysql

# Redis logs
kubectl logs -f deployment/redis
```

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Verify MySQL secrets are created
   - Check MySQL pod is running
   - Ensure database credentials match

2. **Upload Directory Permissions**
   - Verify PVC is properly mounted
   - Check filesystem permissions
   - Ensure www-data user has write access

3. **Backup Failures**
   - Verify backup secrets are configured
   - Check S3 endpoint accessibility
   - Ensure sufficient storage space

### Debug Mode

Enable WordPress debug mode:
```yaml
wordpress:
  env:
    WP_DEBUG: "true"
    WP_DEBUG_LOG: "true"
    WP_DEBUG_DISPLAY: "false"
```

## Security Considerations

- **Immutable Filesystem**: Core WordPress files are read-only
- **Non-root User**: Container runs as www-data (UID 1000)
- **Secrets Management**: All sensitive data stored in Kubernetes secrets
- **Network Policies**: Consider implementing network policies for additional security
- **Regular Updates**: Keep images updated with security patches

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
