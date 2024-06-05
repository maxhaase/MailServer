FROM alpine:latest

# Install necessary packages
RUN apk update && apk add --no-cache \
    apache2 \
    apache2-ssl \
    apache2-proxy \
    apache2-proxy-html \
    apache2-proxy-http \
    apache2-ssl \
    mariadb mariadb-client \
    postfix \
    dovecot \
    postfixadmin \
    roundcubemail \
    wordpress \
    php7 php7-mysqli php7-apache2 php7-json php7-session php7-openssl \
    certbot \
    supervisor \
    bash

# Configure Apache
RUN mkdir -p /run/apache2 && \
    sed -i 's/^#LoadModule/LoadModule/' /etc/apache2/httpd.conf && \
    echo "Include /etc/apache2/sites-enabled/*.conf" >> /etc/apache2/httpd.conf

# Configure MySQL
RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Configure Postfix
COPY postfix/main.cf /etc/postfix/main.cf

# Configure Dovecot
COPY dovecot/dovecot.conf /etc/dovecot/dovecot.conf

# Configure Supervisord
COPY supervisord.conf /etc/supervisord.conf

# Configure services and databases
COPY init.sh /init.sh
RUN chmod +x /init.sh

# Volumes
VOLUME ["/var/www/html", "/var/lib/mysql", "/var/mail", "/etc/letsencrypt"]

# Ports
EXPOSE 80 443 25 110 143 587 993 995

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
