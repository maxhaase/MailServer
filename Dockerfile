FROM alpine:latest

ENV DOMAIN1=maxhaase.com
ENV DOMAIN2=
ENV USER=user
ENV EMAIL=admin@example.com
ENV MYSQL_ROOT_PASSWORD=rootpassword
ENV MYSQL_POSTFIX_PASSWORD=postfixpassword
ENV MYSQL_POSTFIX_DB=postfix

RUN apk update && \
    apk add --no-cache postfix dovecot dovecot-mysql mariadb mariadb-client certbot apache2 php7 php7-apache2 php7-mysqli php7-intl php7-mbstring php7-xml php7-json php7-common php7-curl php7-zip wget unzip openssl bash && \
    mkdir /run/apache2

COPY provision_mail_server.sh /usr/local/bin/provision_mail_server.sh
RUN chmod +x /usr/local/bin/provision_mail_server.sh

ENTRYPOINT ["/usr/local/bin/provision_mail_server.sh"]
