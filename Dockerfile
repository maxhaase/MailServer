# Use the official Ubuntu image
FROM ubuntu:latest

# Environment variables
ARG MYSQL_ROOT_PASSWORD
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD

# Install necessary packages
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-php \
    mariadb-server \
    mariadb-client \
    postfix \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql \
    php php-mysql php-cli php-curl php-json php-gd php-mbstring php-xml \
    postfixadmin \
    roundcube-core roundcube-mysql \
    wordpress \
    supervisor \
    certbot \
    python3-certbot-apache \
    bash

# Copy configurations and scripts
COPY init.sh /init.sh
COPY apache-config.sh /apache-config.sh
RUN chmod +x /init.sh /apache-config.sh

# Configure Apache
RUN mkdir -p /run/apache2 && \
    echo "IncludeOptional /etc/apache2/sites-available/*.conf" >> /etc/apache2/apache2.conf

# Expose necessary ports
EXPOSE 80 443 25 587 993

# Volumes
VOLUME ["/var/lib/mysql", "/var/www/html", "/var/mail", "/etc/letsencrypt"]

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
