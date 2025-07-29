# WordPress PHP-FPM Container
# Based on php:8.4.10-fpm-alpine with WordPress pre-installed

FROM php:8.4.10-fpm-alpine

# Set environment variables
ENV WORDPRESS_VERSION=6.8.2

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    curl \
    wget \
    unzip \
    git \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    openssl-dev \
    icu-dev \
    zlib-dev \
    sqlite-dev \
    gettext \
    mariadb-client \
    netcat-openbsd \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        zip \
        pdo_mysql \
        pdo_sqlite \
        mysqli \
        mbstring \
        exif \
        pcntl \
        bcmath \
        opcache \
        intl \
        soap \
        xml \
    && docker-php-ext-enable opcache \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

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

# Create www-data user and directories
RUN addgroup -g 1000 www-data 2>/dev/null || true && \
    adduser -D -s /bin/sh -u 1000 -G www-data www-data 2>/dev/null || true && \
    mkdir -p /var/www/html

# Download and install WordPress
RUN mkdir -p /tmp/wordpress \
    && curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz" \
    && tar -xzf wordpress.tar.gz -C /tmp/wordpress --strip-components=1 \
    && rm wordpress.tar.gz \
    && cp -r /tmp/wordpress/* /var/www/html/ \
    && rm -rf /tmp/wordpress

# Download and install SQLite Database Integration plugin
RUN mkdir -p /tmp/sqlite-plugin \
    && curl -L -o sqlite-plugin.zip "https://downloads.wordpress.org/plugin/sqlite-database-integration.latest-stable.zip" \
    && unzip sqlite-plugin.zip -d /tmp/sqlite-plugin \
    && cp -r /tmp/sqlite-plugin/* /var/www/html/wp-content/plugins/ \
    && rm -rf /tmp/sqlite-plugin sqlite-plugin.zip

# Copy SQLite db.php file for database integration
RUN cp /var/www/html/wp-content/plugins/sqlite-database-integration/db.copy /var/www/html/wp-content/db.php

# Download and configure the Wonder Cache plugin
RUN mkdir -p /tmp/wonder-cache \
    && curl -L -o wonder-cache.zip "https://downloads.wordpress.org/plugin/wonder-cache.latest-stable.zip" \
    && unzip wonder-cache.zip -d /tmp/wonder-cache \
    && cp /tmp/wonder-cache/wonder-cache/dropins/advanced-cache.php /var/www/html/wp-content/advanced-cache.php \
    && rm -rf /tmp/wonder-cache wonder-cache.zip

# Remove default WordPress plugins and themes
RUN rm -rf /var/www/html/wp-content/plugins/akismet \
    && rm -rf /var/www/html/wp-content/plugins/hello.php \
    && rm -rf /var/www/html/wp-content/themes/twentytwentyfour \
    && rm -rf /var/www/html/wp-content/themes/twentytwentythree \
    && rm -rf /var/www/html/wp-content/themes/twentytwentytwo \
    && rm -rf /var/www/html/wp-content/themes/twentytwentyone \
    && rm -rf /var/www/html/wp-content/themes/twentytwenty

# Download and install Powder theme from GitHub
RUN mkdir -p /tmp/powder-theme \
    && curl -L -o powder-theme.zip "https://github.com/bgardner/powder/archive/refs/heads/main.zip" \
    && unzip powder-theme.zip -d /tmp/powder-theme \
    && mkdir -p /var/www/html/wp-content/themes/powder \
    && cp -r /tmp/powder-theme/powder-main/* /var/www/html/wp-content/themes/powder/ \
    && rm -rf /tmp/powder-theme powder-theme.zip

# Download and install Simple SEO plugin from GitHub
RUN mkdir -p /tmp/simple-seo \
    && curl -L -o simple-seo.zip "https://github.com/bgardner/simple-seo/archive/refs/heads/main.zip" \
    && unzip simple-seo.zip -d /tmp/simple-seo \
    && mkdir -p /var/www/html/wp-content/plugins/simple-seo \
    && cp -r /tmp/simple-seo/simple-seo-main/* /var/www/html/wp-content/plugins/simple-seo/ \
    && rm -rf /tmp/simple-seo simple-seo.zip

# Download and install Modern Footnotes plugin
RUN mkdir -p /tmp/modern-footnotes \
    && curl -L -o modern-footnotes.zip "https://downloads.wordpress.org/plugin/modern-footnotes.latest-stable.zip" \
    && unzip modern-footnotes.zip -d /tmp/modern-footnotes \
    && cp -r /tmp/modern-footnotes/* /var/www/html/wp-content/plugins/ \
    && rm -rf /tmp/modern-footnotes modern-footnotes.zip

# Download and install Two-Factor plugin
RUN mkdir -p /tmp/two-factor \
    && curl -L -o two-factor.zip "https://downloads.wordpress.org/plugin/two-factor.latest-stable.zip" \
    && unzip two-factor.zip -d /tmp/two-factor \
    && cp -r /tmp/two-factor/* /var/www/html/wp-content/plugins/ \
    && rm -rf /tmp/two-factor two-factor.zip

# Create required directories
RUN mkdir -p /var/www/html/wp-content/mu-plugins \
    /var/www/html/wp-content/uploads \
    /var/www/html/wp-content/cache \
    /var/www/html/wp-content/database

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/wp-content/uploads \
    && chmod -R 755 /var/www/html/wp-content/cache \
    && chmod -R 755 /var/www/html/wp-content/database \
    && chmod -R 777 /var/www/html/wp-content/database

# Install WP-CLI
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Copy scripts
COPY scripts/wp-config.php /var/www/html/
COPY scripts/stack-configuration.php /var/www/html/wp-content/mu-plugins/
COPY scripts/entrypoint.sh /usr/local/bin/

# Make entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# Expose port 9000 (PHP-FPM)
EXPOSE 9000

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"] 