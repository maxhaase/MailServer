FROM ubuntu:latest

# Arguments and environment variables
ARG MYSQL_ROOT_PASSWORD
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD

ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE}
ENV MYSQL_USER=${MYSQL_USER}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-php \
    mariadb-server mariadb-client \
    postfix \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql \
    php php-mysql php-cli php-curl php-json php-gd php-mbstring php-xml \
    postfixadmin \
    roundcube-core roundcube-mysql \
    wordpress \
    supervisor \
    certbot python3-certbot-apache \
    bash

# Copy configuration scripts
COPY apache-config.sh /usr/local/bin/apache-config.sh
COPY init.sh /usr/local/bin/init.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/apache-config.sh /usr/local/bin/init.sh

# Expose necessary ports
EXPOSE 80 443 25 587 993 995

# Start supervisor to manage services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
