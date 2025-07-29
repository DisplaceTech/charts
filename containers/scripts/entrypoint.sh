#!/bin/sh
set -e

# Function to install WordPress using WP-CLI
install_wordpress() {
    echo "Installing WordPress using WP-CLI..."
        
    # Get configuration from environment variables
    local site_title="${WP_SITE_TITLE:-My WordPress Site}"
    local admin_username="${WP_ADMIN_USERNAME:-admin}"
    local admin_password="${WP_ADMIN_PASSWORD:-admin123}"
    local admin_email="${WP_ADMIN_EMAIL:-admin@example.com}"
    
    echo "Configuration:"
    echo "- Site Title: $site_title"
    echo "- Admin Username: $admin_username"
    echo "- Admin Email: $admin_email"
    
    # Install WordPress using WP-CLI
    wp core install \
        --path=/var/www/html \
        --url="${WP_SITEURL:-http://localhost:8080}" \
        --title="$site_title" \
        --admin_user="$admin_username" \
        --admin_password="$admin_password" \
        --admin_email="$admin_email" \
        --skip-email \
        --allow-root
    
    # Set additional options
    wp option update permalink_structure '/%postname%/' --allow-root
    wp option update users_can_register 0 --allow-root
    
    echo "WordPress installation completed successfully!"
    echo "You can now log in at: ${WP_SITEURL:-http://localhost:8080}/wp-admin"
}

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Ensure SQLite database directory is writable
mkdir -p /var/www/html/wp-content/database
chown -R www-data:www-data /var/www/html/wp-content/database
chmod -R 777 /var/www/html/wp-content/database

# Create SQLite database file if it doesn't exist
if [ ! -f /var/www/html/wp-content/database/.ht.sqlite ]; then
    touch /var/www/html/wp-content/database/.ht.sqlite
    chown www-data:www-data /var/www/html/wp-content/database/.ht.sqlite
    chmod 666 /var/www/html/wp-content/database/.ht.sqlite
fi

# Check if WordPress is installed and install if needed
if [ -n "$WP_ADMIN_PASSWORD" ] && [ -n "$WP_ADMIN_EMAIL" ]; then
    # Check if WordPress is already installed
    if wp core is-installed --path=/var/www/html --allow-root 2>/dev/null; then
        echo "WordPress is already installed."
    else
        echo "WordPress is not installed. Starting installation..."
    install_wordpress
    fi
fi

# Start PHP-FPM
exec php-fpm 