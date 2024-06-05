FROM ubuntu:latest

ARG MYSQL_ROOT_PASSWORD
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD

ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE}
ENV MYSQL_USER=${MYSQL_USER}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}

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

COPY apache-config/ /etc/apache2/sites-available/
COPY init.sh /usr/local/bin/init.sh
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 80 443 3306

CMD ["/usr/local/bin/init.sh"]
