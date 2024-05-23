FROM alpine:latest

# Environment variables
ENV DOMAIN1=example1.com
ENV DOMAIN2=example2.com
ENV USER=user
ENV EMAIL=user@example.com
ENV MYSQL_POSTFIX_DB=postfix
ENV HOSTNAME=mail.example.com

# Install necessary packages
RUN apk update && \
    apk add --no-cache postfix dovecot dovecot-mysql mariadb mariadb-client certbot apache2 php81 php81-fpm php81-apache2 php81-mysqli php81-intl php81-mbstring php81-xml php81-json php81-common php81-curl php81-zip wget unzip openssl bash

# Expose ports
EXPOSE 25 80 443 587 993 995

# Create a persistent storage volume
VOLUME /var/mail

# Copy the secrets file
COPY secrets.env /root/secrets.env

# Source the secrets file
RUN set -a && source /root/secrets.env && set +a

# Copy provisioning script and make it executable
COPY provision_mail_server.sh /usr/local/bin/provision_mail_server.sh
RUN chmod +x /usr/local/bin/provision_mail_server.sh

# Run the provisioning script
CMD ["/usr/local/bin/provision_mail_server.sh"]
