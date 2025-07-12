# WordPress Helm Charts Makefile
# This Makefile provides targets for building, testing, and deploying the WordPress Helm charts

# Variables
DOCKER_REGISTRY ?= ghcr.io
DOCKER_USERNAME ?= displacetech
IMAGE_NAME ?= wordpress
WORDPRESS_VERSION ?= 6.8.1
PHP_VERSION ?= 8.4.10
IMAGE_TAG ?= $(WORDPRESS_VERSION)-$(PHP_VERSION)
LATEST_TAG ?= latest

# Helm variables
HELM_CHART_PATH ?= wordpress
HELM_RELEASE_NAME ?= wordpress
HELM_NAMESPACE ?= wordpress

# Kubernetes variables
KUBECONFIG ?= ~/.kube/config

# Backup variables
BACKUP_ENABLED ?= false

.PHONY: help build-image build-and-push-image test-image clean-image
.PHONY: helm-package helm-install helm-upgrade helm-uninstall helm-test
.PHONY: secrets-create secrets-delete backup-setup backup-test
.PHONY: lint test clean

# Default target
help: ## Show this help message
	@echo "WordPress Helm Charts - Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Docker image targets
build-image: ## Build the WordPress Docker image locally
	@echo "Building WordPress Docker image..."
	docker build -t $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) containers/
	docker tag $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(LATEST_TAG)
	@echo "Image built successfully: $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)"

build-and-push-image: build-image ## Build and push the WordPress Docker image to registry
	@echo "Pushing WordPress Docker image to registry..."
	docker push $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(LATEST_TAG)
	@echo "Image pushed successfully"

test-image: build-image ## Test the WordPress Docker image
	@echo "Testing WordPress Docker image..."
	docker run --rm -p 8080:80 $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) &
	@sleep 10
	@curl -f http://localhost:8080 || (echo "Image test failed" && exit 1)
	@docker stop $$(docker ps -q --filter ancestor=$(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG))
	@echo "Image test passed"

clean-image: ## Remove local WordPress Docker images
	@echo "Cleaning WordPress Docker images..."
	docker rmi $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	docker rmi $(DOCKER_REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME):$(LATEST_TAG) 2>/dev/null || true
	@echo "Images cleaned"

# Helm chart targets
helm-package: ## Package the Helm chart
	@echo "Packaging Helm chart..."
	helm package $(HELM_CHART_PATH)
	@echo "Chart packaged successfully"

helm-install: ## Install the WordPress Helm chart
	@echo "Installing WordPress Helm chart..."
	kubectl create namespace $(HELM_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm install $(HELM_RELEASE_NAME) $(HELM_CHART_PATH) \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		--wait \
		--timeout 10m
	@echo "WordPress installed successfully"

helm-upgrade: ## Upgrade the WordPress Helm chart
	@echo "Upgrading WordPress Helm chart..."
	helm upgrade $(HELM_RELEASE_NAME) $(HELM_CHART_PATH) \
		--namespace $(HELM_NAMESPACE) \
		--wait \
		--timeout 10m
	@echo "WordPress upgraded successfully"

helm-uninstall: ## Uninstall the WordPress Helm chart
	@echo "Uninstalling WordPress Helm chart..."
	helm uninstall $(HELM_RELEASE_NAME) --namespace $(HELM_NAMESPACE)
	kubectl delete namespace $(HELM_NAMESPACE) --ignore-not-found=true
	@echo "WordPress uninstalled successfully"

helm-test: ## Test the Helm chart
	@echo "Testing Helm chart..."
	helm template $(HELM_RELEASE_NAME) $(HELM_CHART_PATH) --namespace $(HELM_NAMESPACE) > /tmp/wordpress-manifests.yaml
	@echo "Chart templates generated successfully"

# Secrets management targets
secrets-create: ## Create required Kubernetes secrets
	@echo "Creating Kubernetes secrets..."
	@echo "Please provide the following values when prompted:"
	@read -p "Database name [wordpress]: " db_name; \
	read -p "Database user [wordpress]: " db_user; \
	read -s -p "Database password: " db_password; echo; \
	read -p "Database host [mysql]: " db_host; \
	read -s -p "MySQL root password: " mysql_root_password; echo; \
	read -p "WordPress admin email: " wp_admin_email; \
	read -s -p "WordPress admin password: " wp_admin_password; echo; \
	read -s -p "WordPress auth key: " wp_auth_key; echo; \
	read -s -p "WordPress secure auth key: " wp_secure_auth_key; echo; \
	read -s -p "WordPress logged in key: " wp_logged_in_key; echo; \
	read -s -p "WordPress nonce key: " wp_nonce_key; echo; \
	read -s -p "WordPress auth salt: " wp_auth_salt; echo; \
	read -s -p "WordPress secure auth salt: " wp_secure_auth_salt; echo; \
	read -s -p "WordPress logged in salt: " wp_logged_in_salt; echo; \
	read -s -p "WordPress nonce salt: " wp_nonce_salt; echo; \
	kubectl create namespace $(HELM_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -; \
	kubectl create secret generic wordpress-secrets \
		--namespace $(HELM_NAMESPACE) \
		--from-literal=db-name="$${db_name:-wordpress}" \
		--from-literal=db-user="$${db_user:-wordpress}" \
		--from-literal=db-password="$$db_password" \
		--from-literal=db-host="$${db_host:-mysql}" \
		--from-literal=wp-auth-key="$$wp_auth_key" \
		--from-literal=wp-secure-auth-key="$$wp_secure_auth_key" \
		--from-literal=wp-logged-in-key="$$wp_logged_in_key" \
		--from-literal=wp-nonce-key="$$wp_nonce_key" \
		--from-literal=wp-auth-salt="$$wp_auth_salt" \
		--from-literal=wp-secure-auth-salt="$$wp_secure_auth_salt" \
		--from-literal=wp-logged-in-salt="$$wp_logged_in_salt" \
		--from-literal=wp-nonce-salt="$$wp_nonce_salt" \
		--from-literal=wp-admin-email="$$wp_admin_email" \
		--from-literal=wp-admin-password="$$wp_admin_password" \
		--dry-run=client -o yaml | kubectl apply -f -; \
	kubectl create secret generic mysql-secrets \
		--namespace $(HELM_NAMESPACE) \
		--from-literal=mysql-root-password="$$mysql_root_password" \
		--from-literal=mysql-database="$${db_name:-wordpress}" \
		--from-literal=mysql-user="$${db_user:-wordpress}" \
		--from-literal=mysql-password="$$db_password" \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo "Secrets created successfully"

secrets-delete: ## Delete Kubernetes secrets
	@echo "Deleting Kubernetes secrets..."
	kubectl delete secret wordpress-secrets --namespace $(HELM_NAMESPACE) --ignore-not-found=true
	kubectl delete secret mysql-secrets --namespace $(HELM_NAMESPACE) --ignore-not-found=true
	kubectl delete secret backup-secrets --namespace $(HELM_NAMESPACE) --ignore-not-found=true
	@echo "Secrets deleted successfully"

# Backup targets
backup-setup: ## Setup backup secrets
	@echo "Setting up backup secrets..."
	@echo "Please provide the following S3 backup configuration:"
	@read -p "S3 endpoint: " s3_endpoint; \
	read -p "S3 access key: " s3_access_key; \
	read -s -p "S3 secret key: " s3_secret_key; echo; \
	read -p "S3 bucket: " s3_bucket; \
	read -p "S3 region [us-east-1]: " s3_region; \
	kubectl create secret generic backup-secrets \
		--namespace $(HELM_NAMESPACE) \
		--from-literal=s3-endpoint="$$s3_endpoint" \
		--from-literal=s3-access-key="$$s3_access_key" \
		--from-literal=s3-secret-key="$$s3_secret_key" \
		--from-literal=s3-bucket="$$s3_bucket" \
		--from-literal=s3-region="$${s3_region:-us-east-1}" \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo "Backup secrets created successfully"

backup-test: ## Test backup functionality
	@echo "Testing backup functionality..."
	kubectl create job --from=cronjob/$(HELM_RELEASE_NAME)-uploads-backup manual-uploads-backup --namespace $(HELM_NAMESPACE)
	kubectl create job --from=cronjob/$(HELM_RELEASE_NAME)-database-backup manual-database-backup --namespace $(HELM_NAMESPACE)
	@echo "Backup jobs created. Check status with: kubectl get jobs -n $(HELM_NAMESPACE)"

# Development targets
local-serve: ## Start local development server with Docker Compose
	@echo "Starting local development server..."
	docker compose up --build -d
	@echo "WordPress is available at http://localhost:8080"
	@echo "Admin credentials: admin@example.com / admin123"

local-stop: ## Stop local development server
	@echo "Stopping local development server..."
	docker compose down

local-logs: ## View local development logs
	docker compose logs -f

lint: ## Lint the Helm chart
	@echo "Linting Helm chart..."
	helm lint $(HELM_CHART_PATH)
	@echo "Chart linting completed"

test: helm-test test-image ## Run all tests
	@echo "All tests completed successfully"

clean: clean-image ## Clean up all resources
	@echo "Cleaning up resources..."
	rm -f *.tgz
	@echo "Cleanup completed"

# CI/CD targets
ci-build: ## CI build target
	@echo "Running CI build..."
	make build-and-push-image
	make helm-package
	@echo "CI build completed"

ci-deploy: ## CI deploy target
	@echo "Running CI deployment..."
	make helm-upgrade
	@echo "CI deployment completed"

# Documentation targets
docs: ## Generate documentation
	@echo "Generating documentation..."
	helm-docs --chart-search-root=.
	@echo "Documentation generated"

# Monitoring targets
status: ## Show deployment status
	@echo "WordPress deployment status:"
	kubectl get pods,svc,pvc -n $(HELM_NAMESPACE)
	@echo ""
	@echo "WordPress logs:"
	kubectl logs -f deployment/$(HELM_RELEASE_NAME) -n $(HELM_NAMESPACE) --tail=50

logs: ## Show WordPress logs
	kubectl logs -f deployment/$(HELM_RELEASE_NAME) -n $(HELM_NAMESPACE)

mysql-logs: ## Show MySQL logs
	kubectl logs -f deployment/$(HELM_RELEASE_NAME)-mysql -n $(HELM_NAMESPACE)

redis-logs: ## Show Redis logs
	kubectl logs -f deployment/$(HELM_RELEASE_NAME) -c redis -n $(HELM_NAMESPACE) 