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
    debconf-utils \
    bash

# Preseed debconf values
RUN echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
RUN echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
RUN echo "roundcube-core roundcube/dbconfig-install boolean true" | debconf-set-selections
RUN echo "roundcube-core roundcube/mysql/admin-pass password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections
RUN echo "roundcube-core roundcube/mysql/app-pass password ${MYSQL_PASSWORD}" | debconf-set-selections
RUN echo "roundcube-core roundcube/app-password-confirm password ${MYSQL_PASSWORD}" | debconf-set-selections
RUN echo "roundcube-core roundcube/mysql/admin-user string root" | debconf-set-selections
RUN echo "roundcube-core roundcube/internal/skip-preseed boolean true" | debconf-set-selections
RUN echo "postfixadmin postfixadmin/dbconfig-install boolean true" | debconf-set-selections
RUN echo "postfixadmin postfixadmin/mysql/admin-pass password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections
RUN echo "postfixadmin postfixadmin/mysql/app-pass password ${MYSQL_PASSWORD}" | debconf-set-selections
RUN echo "postfixadmin postfixadmin/app-password-confirm password ${MYSQL_PASSWORD}" | debconf-set-selections
RUN echo "postfixadmin postfixadmin/mysql/admin-user string root" | debconf-set-selections
RUN echo "postfixadmin postfixadmin/internal/skip-preseed boolean true" | debconf-set-selections

COPY apache-config/ /etc/apache2/sites-available/
COPY init.sh /init.sh

RUN chmod +x /init.sh

CMD ["/init.sh"]
