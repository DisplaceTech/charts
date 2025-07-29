# WordPress Helm Charts - Quick Start Guide

This guide will help you get WordPress running on Kubernetes in under 10 minutes.

## Prerequisites

- Kubernetes cluster (1.20+)
- Helm 3.x
- kubectl configured
- Docker (for building images)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/charts.git
cd charts
```

### 2. Build the Docker Image

```bash
# Update the Docker registry in Makefile
sed -i 's/your-username/YOUR_GITHUB_USERNAME/g' Makefile

# Build and push the image
make build-and-push-image
```

### 3. Create Required Secrets

```bash
# Create secrets interactively
make secrets-create
```

This will prompt you for:
- Database credentials
- WordPress admin credentials
- WordPress security keys and salts

### 4. Deploy WordPress

```bash
# For development
helm install wordpress wordpress/ \
  --namespace wordpress \
  --create-namespace \
  --values wordpress/values-development.yaml

# For production
helm install wordpress wordpress/ \
  --namespace wordpress \
  --create-namespace \
  --values wordpress/values-production.yaml
```

### 5. Access WordPress

```bash
# Port forward to access WordPress
kubectl port-forward svc/wordpress 8080:80 -n wordpress
```

Then open http://localhost:8080 in your browser.

## Configuration

### Environment-Specific Values

- **Development**: `wordpress/values-development.yaml`
- **Production**: `wordpress/values-production.yaml`
- **Custom**: Create your own values file

### Key Configuration Options

```yaml
# WordPress settings
wordpress:
  replicaCount: 1  # Number of WordPress pods
  image:
    repository: ghcr.io/your-username/wordpress
    tag: "latest"
  
  # Resource limits
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

# Database settings
mysql:
  enabled: true
  persistence:
    size: 10Gi

# Redis caching
redis:
  enabled: true

# Backups
backups:
  enabled: true
  uploads:
    schedule: "0 2 * * 0"  # Weekly
    retention: 30
```

## Backup Setup

### 1. Create Backup Secrets

```bash
make backup-setup
```

### 2. Test Backups

```bash
make backup-test
```

### 3. Monitor Backup Jobs

```bash
kubectl get cronjobs -n wordpress
kubectl get jobs -n wordpress
```

## Monitoring

### Check Deployment Status

```bash
make status
```

### View Logs

```bash
# WordPress logs
make logs

# MySQL logs
make mysql-logs

# Redis logs
make redis-logs
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Check if image exists
   docker pull ghcr.io/your-username/wordpress:latest
   
   # Update image repository in values
   helm upgrade wordpress wordpress/ --set wordpress.image.repository=your-registry/wordpress
   ```

2. **Database Connection Issues**
   ```bash
   # Check MySQL pod
   kubectl get pods -n wordpress -l app.kubernetes.io/component=mysql
   
   # Check MySQL logs
   kubectl logs -f deployment/wordpress-mysql -n wordpress
   ```

3. **Persistent Volume Issues**
   ```bash
   # Check PVC status
   kubectl get pvc -n wordpress
   
   # Check storage class
   kubectl get storageclass
   ```

### Debug Mode

Enable WordPress debug mode:

```yaml
wordpress:
  env:
    WP_DEBUG: "true"
    WP_DEBUG_LOG: "true"
    WP_DEBUG_DISPLAY: "false"
```

## Scaling

### Horizontal Scaling

```bash
# Scale WordPress pods
kubectl scale deployment wordpress --replicas=3 -n wordpress

# Or use HPA (if enabled)
kubectl get hpa -n wordpress
```

### Vertical Scaling

Update resource limits in values file:

```yaml
wordpress:
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
```

## Upgrades

### Update WordPress Version

```bash
# Build new image
make build-and-push-image

# Upgrade deployment
helm upgrade wordpress wordpress/ \
  --namespace wordpress \
  --set wordpress.image.tag=6.8.2-8.4.10
```

### Update Helm Chart

```bash
# Update chart
helm upgrade wordpress wordpress/ \
  --namespace wordpress \
  --values your-custom-values.yaml
```

## Cleanup

### Remove Deployment

```bash
# Uninstall WordPress
make helm-uninstall

# Or manually
helm uninstall wordpress -n wordpress
kubectl delete namespace wordpress
```

### Remove Secrets

```bash
make secrets-delete
```

## Next Steps

1. **Configure Ingress**: Set up external access with SSL
2. **Set up Monitoring**: Add Prometheus and Grafana
3. **Configure Backups**: Set up S3-compatible storage
4. **Security Hardening**: Enable network policies and pod security standards
5. **Performance Tuning**: Optimize Redis and MySQL settings

## Support

- **Documentation**: See the main README.md
- **Issues**: Report bugs on GitHub
- **Discussions**: Ask questions in GitHub Discussions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

Happy deploying! 🚀 