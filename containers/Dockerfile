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

# Copy mu-plugin to activate required plugins and theme
COPY scripts/auto-activate.php /var/www/html/wp-content/mu-plugins/

# Copy wp-config.php template
COPY scripts/wp-config.php.template /var/www/html/

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/

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