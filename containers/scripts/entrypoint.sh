#!/bin/bash
set -e

# Function to generate random strings
generate_random_string() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to replace environment variables in wp-config.php
setup_wp_config() {
    if [ ! -f /var/www/html/wp-config.php ]; then
        echo "Setting up wp-config.php..."
        
        # Generate salts if not provided
        export WP_AUTH_KEY=${WP_AUTH_KEY:-$(generate_random_string)}
        export WP_SECURE_AUTH_KEY=${WP_SECURE_AUTH_KEY:-$(generate_random_string)}
        export WP_LOGGED_IN_KEY=${WP_LOGGED_IN_KEY:-$(generate_random_string)}
        export WP_NONCE_KEY=${WP_NONCE_KEY:-$(generate_random_string)}
        export WP_AUTH_SALT=${WP_AUTH_SALT:-$(generate_random_string)}
        export WP_SECURE_AUTH_SALT=${WP_SECURE_AUTH_SALT:-$(generate_random_string)}
        export WP_LOGGED_IN_SALT=${WP_LOGGED_IN_SALT:-$(generate_random_string)}
        export WP_NONCE_SALT=${WP_NONCE_SALT:-$(generate_random_string)}
        
        # Set default values for other variables
        export DB_NAME=${DB_NAME:-wordpress}
        export DB_USER=${DB_USER:-wordpress}
        export DB_PASSWORD=${DB_PASSWORD}
        export DB_HOST=${DB_HOST:-mysql}
        export WP_DEBUG=${WP_DEBUG:-false}
        export WP_DEBUG_LOG=${WP_DEBUG_LOG:-false}
        export WP_DEBUG_DISPLAY=${WP_DEBUG_DISPLAY:-false}
        export WP_CACHE=${WP_CACHE:-true}
        export REDIS_HOST=${REDIS_HOST:-localhost}
        export REDIS_PORT=${REDIS_PORT:-6379}
        export REDIS_PASSWORD=${REDIS_PASSWORD:-}
        export REDIS_DATABASE=${REDIS_DATABASE:-0}
        
        # Process template
        envsubst < /var/www/html/wp-config.php.template > /var/www/html/wp-config.php
        
        echo "wp-config.php created successfully"
    fi
}

# Function to wait for database
wait_for_database() {
    echo "Waiting for database connection..."
    while ! mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --silent; do
        sleep 2
    done
    echo "Database is ready"
}

# Function to install WordPress
install_wordpress() {
    if [ ! -f /var/www/html/.installed ]; then
        echo "Installing WordPress..."
        
        # Wait for database
        wait_for_database
        
        # Run WordPress installation script
        php /var/www/html/install-wordpress.php
        
        # Mark as installed
        touch /var/www/html/.installed
        echo "WordPress installation completed"
    fi
}

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Setup wp-config.php
setup_wp_config

# Install WordPress if needed
if [ -n "$WP_ADMIN_PASSWORD" ] && [ -n "$WP_ADMIN_EMAIL" ]; then
    install_wordpress
fi

# Start Apache
exec httpd -D FOREGROUND 