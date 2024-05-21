FROM alpine:latest

ENV DOMAIN1=maxhaase.com
ENV DOMAIN2=
ENV USER=user
ENV EMAIL=admin@example.com
ENV USER_PASSWORD=UserPassword
ENV MYSQL_ROOT_PASSWORD=rootPassword
ENV MYSQL_POSTFIX_PASSWORD=postfixPassword
ENV MYSQL_POSTFIX_DB=postfix
ENV HOSTNAME=mail.maxhaase.com

RUN apk update && \
    apk add --no-cache postfix dovecot dovecot-mysql mariadb mariadb-client certbot apache2 php81 php81-fpm php81-apache2 php81-mysqli php81-intl php81-mbstring php81-xml php81-json php81-common php81-curl php81-zip wget unzip openssl bash



COPY provision_mail_server.sh /usr/local/bin/provision_mail_server.sh
RUN chmod +x /usr/local/bin/provision_mail_server.sh

ENTRYPOINT ["/usr/local/bin/provision_mail_server.sh"]
