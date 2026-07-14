FROM alpine:3.18

LABEL org.opencontainers.image.title="pujo-mfix-task"
LABEL org.opencontainers.image.description="Alpine image with Nginx and PHP 8.2"

RUN apk add --no-cache \
        nginx \
        nginx-mod-http-headers-more \
        php82 \
        php82-fpm \
        libcap \
    && mkdir -p /run/nginx /var/www/html \
    && chown -R nginx:nginx /run/nginx /var/www/html /var/lib/nginx /var/log/nginx /var/log/php82 \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

WORKDIR /var/www/html

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/http.d/default.conf
COPY php-fpm/www.conf /etc/php82/php-fpm.d/www.conf
COPY php-fpm/99-security.ini /etc/php82/conf.d/99-security.ini
COPY --chown=nginx:nginx index.php ./index.php
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint

RUN chmod +x /usr/local/bin/docker-entrypoint

EXPOSE 80

USER nginx

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
