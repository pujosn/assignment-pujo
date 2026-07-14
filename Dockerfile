FROM alpine:3.18

LABEL org.opencontainers.image.title="pujo-mfix-task"
LABEL org.opencontainers.image.description="Alpine image with Nginx and PHP 8.2"

RUN apk add --no-cache \
        nginx \
        php82 \
        php82-fpm \
    && mkdir -p /run/nginx /var/www/html

WORKDIR /var/www/html

COPY nginx/default.conf /etc/nginx/http.d/default.conf
COPY index.php ./index.php
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint

RUN chmod +x /usr/local/bin/docker-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]