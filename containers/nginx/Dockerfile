# Nginx Web Server for WordPress
# Based on nginx:alpine

FROM nginx:alpine

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY wordpress.conf /etc/nginx/conf.d/default.conf

# Create nginx user and directories
RUN addgroup -g 1000 nginx 2>/dev/null || true && \
    adduser -D -s /bin/sh -u 1000 -G nginx nginx 2>/dev/null || true && \
    mkdir -p /var/www/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"] 