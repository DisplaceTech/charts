# WordPress Custom Image
# Based on php:8.4.10-alpine with manually installed Apache and pre-installed themes and plugins

FROM php:8.4.10-alpine AS builder

# Set environment variables
ENV WORDPRESS_VERSION=6.8.1
ENV PHP_VERSION=8.4.10

# Install build dependencies, Apache, and PHP extensions in one layer
RUN apk add --no-cache \
    curl \
    wget \
    unzip \
    git \
    apache2 \
    apache2-utils \
    autoconf \
    build-base \
    libzip-dev \
    libpng-dev \
    jpeg-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    openssl-dev \
    icu-dev \
    gd-dev \
    imagemagick-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
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
    && docker-php-ext-enable opcache \
    && pecl install redis imagick \
    && docker-php-ext-enable redis imagick \
    && apk del \
        autoconf \
        build-base \
        libzip-dev \
        libpng-dev \
        jpeg-dev \
        freetype-dev \
        oniguruma-dev \
        libxml2-dev \
        openssl-dev \
        icu-dev \
        gd-dev \
        imagemagick-dev \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Download WordPress and plugins in builder stage
RUN mkdir -p /tmp/wordpress /tmp/plugins /tmp/themes \
    && curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz" \
    && tar -xzf wordpress.tar.gz -C /tmp/wordpress --strip-components=1 \
    && rm wordpress.tar.gz

# Download plugins and clone themes/plugins in one layer
RUN curl -o redis-cache.zip -fSL "https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip" \
    && unzip redis-cache.zip -d /tmp/plugins/ \
    && rm redis-cache.zip \
    && curl -o batcache.zip -fSL "https://downloads.wordpress.org/plugin/batcache.latest-stable.zip" \
    && unzip batcache.zip -d /tmp/plugins/ \
    && rm batcache.zip \
    && git clone --depth 1 --branch main https://github.com/bgardner/powder.git /tmp/themes/powder \
    && git clone --depth 1 --branch main https://github.com/bgardner/simple-seo.git /tmp/plugins/simple-seo \
    && rm -rf /tmp/themes/powder/.git /tmp/plugins/simple-seo/.git

# Final stage - runtime image
FROM php:8.4.10-alpine

# Install only runtime dependencies and Apache
RUN apk add --no-cache \
    curl \
    apache2 \
    apache2-utils \
    libzip \
    libpng \
    libjpeg \
    freetype \
    oniguruma \
    libxml2 \
    openssl \
    icu \
    gd \
    imagemagick \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Copy PHP extensions from builder
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

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

# Configure Apache
RUN echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/apache2/httpd.conf \
    && echo "LoadModule headers_module modules/mod_headers.so" >> /etc/apache2/httpd.conf \
    && echo "LoadModule expires_module modules/mod_expires.so" >> /etc/apache2/httpd.conf \
    && echo "ServerName localhost" >> /etc/apache2/httpd.conf \
    && sed -i 's/#ServerName www.example.com:80/ServerName localhost/' /etc/apache2/httpd.conf \
    && echo "DocumentRoot /var/www/html" >> /etc/apache2/httpd.conf \
    && echo "<Directory /var/www/html>" >> /etc/apache2/httpd.conf \
    && echo "    AllowOverride All" >> /etc/apache2/httpd.conf \
    && echo "    Require all granted" >> /etc/apache2/httpd.conf \
    && echo "</Directory>" >> /etc/apache2/httpd.conf

# The PHP Alpine image already includes www-data user, just ensure directories exist
RUN mkdir -p /var/www/html

# Copy WordPress files from builder
COPY --from=builder /tmp/wordpress/ /var/www/html/

# Copy plugins and themes from builder
COPY --from=builder /tmp/plugins/redis-cache/ /var/www/html/wp-content/plugins/redis-cache/
COPY --from=builder /tmp/plugins/batcache/ /var/www/html/wp-content/plugins/batcache/
COPY --from=builder /tmp/plugins/simple-seo/ /var/www/html/wp-content/plugins/simple-seo/
COPY --from=builder /tmp/themes/powder/ /var/www/html/wp-content/themes/powder/

# Remove default themes and plugins
RUN cd /var/www/html/wp-content/themes && \
    rm -rf twentytwentythree twentytwentytwo twentytwentyone twentytwenty

RUN cd /var/www/html/wp-content/plugins && \
    rm -rf akismet hello.php

# Create directories and set permissions
RUN mkdir -p /var/www/html/wp-content/mu-plugins \
    /var/www/html/wp-content/uploads \
    /var/www/html/wp-content/cache \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/wp-content/uploads \
    && chmod -R 755 /var/www/html/wp-content/cache

# Copy scripts
COPY scripts/auto-activate.php /var/www/html/wp-content/mu-plugins/
COPY scripts/wp-config.php.template /var/www/html/
COPY scripts/install-wordpress.php /var/www/html/
COPY scripts/entrypoint.sh /usr/local/bin/

# Make entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# Expose port 80
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"] 