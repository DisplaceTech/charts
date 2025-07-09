# WordPress Custom Image
# Based on php:8.4.10-apache-bookworm with pre-installed themes and plugins

FROM php:8.4.10-apache-bookworm

# Set environment variables
ENV WORDPRESS_VERSION=6.8.1
ENV WORDPRESS_SHA1=05efd37087055c4c1affa19270bd9aab770c0e0f
ENV PHP_VERSION=8.4.10

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libssl-dev \
    libmcrypt-dev \
    libicu-dev \
    libgd-dev \
    libmagickwand-dev \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    zip \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    opcache \
    intl \
    soap \
    xml \
    && docker-php-ext-enable opcache

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install ImageMagick extension
RUN pecl install imagick && docker-php-ext-enable imagick

# Configure PHP
RUN { \
    echo 'memory_limit = 256M'; \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_vars = 3000'; \
    echo 'date.timezone = UTC'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.enable_cli = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.interned_strings_buffer = 8'; \
    echo 'opcache.max_accelerated_files = 4000'; \
    echo 'opcache.revalidate_freq = 2'; \
    echo 'opcache.fast_shutdown = 1'; \
} > /usr/local/etc/php/conf.d/wordpress.ini

# Enable Apache modules
RUN a2enmod rewrite headers expires

# Create www-data user with specific UID/GID
RUN groupadd -g 1000 www-data && \
    useradd -u 1000 -g www-data -s /bin/bash -m www-data

# Download and install WordPress
RUN curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz" \
    && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
    && tar -xzf wordpress.tar.gz -C /var/www/html --strip-components=1 \
    && rm wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/html

# Download and install Redis Object Cache plugin
RUN curl -o redis-cache.zip -fSL "https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip" \
    && unzip redis-cache.zip -d /tmp/ \
    && mv /tmp/redis-cache /var/www/html/wp-content/plugins/ \
    && rm redis-cache.zip

# Download and install Batcache plugin
RUN curl -o batcache.zip -fSL "https://downloads.wordpress.org/plugin/batcache.latest-stable.zip" \
    && unzip batcache.zip -d /tmp/ \
    && mv /tmp/batcache /var/www/html/wp-content/plugins/ \
    && rm batcache.zip

# Clone and install Powder theme
RUN git clone --depth 1 --branch $(git ls-remote --tags https://github.com/bgardner/powder.git | tail -n 1 | cut -d/ -f3) \
    https://github.com/bgardner/powder.git /tmp/powder \
    && mv /tmp/powder /var/www/html/wp-content/themes/powder \
    && rm -rf /tmp/powder/.git

# Clone and install Simple SEO plugin
RUN git clone --depth 1 --branch $(git ls-remote --tags https://github.com/bgardner/simple-seo.git | tail -n 1 | cut -d/ -f3) \
    https://github.com/bgardner/simple-seo.git /tmp/simple-seo \
    && mv /tmp/simple-seo /var/www/html/wp-content/plugins/simple-seo \
    && rm -rf /tmp/simple-seo/.git

# Remove default themes
RUN cd /var/www/html/wp-content/themes && \
    rm -rf twentytwentythree twentytwentytwo twentytwentyone twentytwenty

# Remove default plugins
RUN cd /var/www/html/wp-content/plugins && \
    rm -rf akismet hello.php

# Create mu-plugins directory and add autoloader
RUN mkdir -p /var/www/html/wp-content/mu-plugins

# Create mu-plugin to activate required plugins and theme
RUN cat > /var/www/html/wp-content/mu-plugins/auto-activate.php << 'EOF'
<?php
/**
 * Auto-activate required plugins and theme
 * This mu-plugin runs before WordPress loads
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/');
}

// Hook into WordPress init to activate plugins and theme
add_action('init', function() {
    // Only run on first install or if plugins are not active
    if (!get_option('auto_plugins_activated')) {
        
        // Activate Redis Object Cache
        if (!is_plugin_active('redis-cache/redis-cache.php')) {
            activate_plugin('redis-cache/redis-cache.php');
        }
        
        // Activate Batcache
        if (!is_plugin_active('batcache/batcache.php')) {
            activate_plugin('batcache/batcache.php');
        }
        
        // Activate Simple SEO
        if (!is_plugin_active('simple-seo/simple-seo.php')) {
            activate_plugin('simple-seo/simple-seo.php');
        }
        
        // Switch to Powder theme
        $current_theme = get_option('stylesheet');
        if ($current_theme !== 'powder') {
            switch_theme('powder');
        }
        
        // Mark as activated
        update_option('auto_plugins_activated', true);
    }
});

// Override get_option for active plugins to ensure our plugins are always considered active
add_filter('option_active_plugins', function($active_plugins) {
    $required_plugins = [
        'redis-cache/redis-cache.php',
        'batcache/batcache.php',
        'simple-seo/simple-seo.php'
    ];
    
    foreach ($required_plugins as $plugin) {
        if (!in_array($plugin, $active_plugins)) {
            $active_plugins[] = $plugin;
        }
    }
    
    return $active_plugins;
});

// Override get_option for active theme
add_filter('option_stylesheet', function($stylesheet) {
    return 'powder';
});

add_filter('option_template', function($template) {
    return 'powder';
});
EOF

# Create wp-config.php template
RUN cat > /var/www/html/wp-config.php.template << 'EOF'
<?php
/**
 * WordPress configuration template
 * This file will be processed by envsubst to replace environment variables
 */

// Database configuration
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASSWORD}');
define('DB_HOST', '${DB_HOST}');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// Authentication unique keys and salts
define('AUTH_KEY',         '${WP_AUTH_KEY}');
define('SECURE_AUTH_KEY',  '${WP_SECURE_AUTH_KEY}');
define('LOGGED_IN_KEY',    '${WP_LOGGED_IN_KEY}');
define('NONCE_KEY',        '${WP_NONCE_KEY}');
define('AUTH_SALT',        '${WP_AUTH_SALT}');
define('SECURE_AUTH_SALT', '${WP_SECURE_AUTH_SALT}');
define('LOGGED_IN_SALT',   '${WP_LOGGED_IN_SALT}');
define('NONCE_SALT',       '${WP_NONCE_SALT}');

// WordPress settings
define('WP_DEBUG', ${WP_DEBUG});
define('WP_DEBUG_LOG', ${WP_DEBUG_LOG});
define('WP_DEBUG_DISPLAY', ${WP_DEBUG_DISPLAY});
define('WP_CACHE', ${WP_CACHE});

// Redis configuration
define('WP_REDIS_HOST', '${REDIS_HOST}');
define('WP_REDIS_PORT', ${REDIS_PORT});
define('WP_REDIS_PASSWORD', '${REDIS_PASSWORD}');
define('WP_REDIS_DATABASE', ${REDIS_DATABASE});

// Security settings
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_AUTO_UPDATE_CORE', false);

// Performance settings
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

// Multisite (disabled by default)
// define('WP_ALLOW_MULTISITE', true);

// Absolute path to the WordPress directory
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

// Sets up WordPress vars and included files
require_once ABSPATH . 'wp-settings.php';
EOF

# Create entrypoint script
RUN cat > /usr/local/bin/entrypoint.sh << 'EOF'
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
        
        # Install WordPress
        wp core install \
            --url="${WP_URL:-http://localhost}" \
            --title="${WP_TITLE:-WordPress Site}" \
            --admin_user="${WP_ADMIN_USER:-admin}" \
            --admin_password="${WP_ADMIN_PASSWORD}" \
            --admin_email="${WP_ADMIN_EMAIL}" \
            --skip-email \
            --allow-root
        
        # Mark as installed
        touch /var/www/html/.installed
        echo "WordPress installed successfully"
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
exec apache2-foreground
EOF

# Make entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Install WP-CLI
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Create uploads directory with proper permissions
RUN mkdir -p /var/www/html/wp-content/uploads \
    && chown -R www-data:www-data /var/www/html/wp-content/uploads \
    && chmod -R 755 /var/www/html/wp-content/uploads

# Create cache directory for Batcache
RUN mkdir -p /var/www/html/wp-content/cache \
    && chown -R www-data:www-data /var/www/html/wp-content/cache \
    && chmod -R 755 /var/www/html/wp-content/cache

# Set working directory
WORKDIR /var/www/html

# Expose port 80
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"] 