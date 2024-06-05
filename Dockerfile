# Use the official Alpine image
FROM alpine:latest

# Environment variables
ARG MYSQL_ROOT_PASSWORD
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD

# Install necessary packages
RUN apk update && apk add --no-cache \
    apache2 \
    apache2-ssl \
    apache2-proxy \
    mariadb mariadb-client \
    postfix \
    dovecot \
    php7 php7-mysqli php7-session php7-openssl php7-json php7-phar php7-curl php7-xml \
    php7-mbstring php7-gd php7-ctype php7-dom \
    postfixadmin \
    roundcubemail \
    wordpress \
    supervisor \
    certbot \
    bash

# Copy configurations
COPY apache-config/ /etc/apache2/sites-available/
COPY postfix-config/ /etc/postfix/
COPY dovecot-config/ /etc/dovecot/
COPY supervisord.conf /etc/supervisord.conf
COPY init.sh /init.sh
RUN chmod +x /init.sh

# Configure Apache
RUN mkdir -p /run/apache2 && \
    echo "IncludeOptional /etc/apache2/sites-available/*.conf" >> /etc/apache2/httpd.conf

# Expose necessary ports
EXPOSE 80 443 25 587 993

# Volumes
VOLUME ["/var/lib/mysql", "/var/www/html", "/var/mail", "/etc/letsencrypt"]

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
