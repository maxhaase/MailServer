#!/bin/bash

# Start MySQL service
service mysql start

# Wait for MySQL to be ready
while ! mysqladmin ping --silent; do
    sleep 1
done

# Initialize MySQL database and users
mysql -u root -p${MYSQL_ROOT_PASSWORD} <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Run Apache configuration script
/usr/local/bin/apache-config.sh

# Set up Certbot for SSL certificates
certbot --apache --non-interactive --agree-tos --email admin@${DOMAIN1} -d ${DOMAIN1} -d ${MAIL_DOMAIN} -d ${ADMIN_DOMAIN} -d ${WEBMAIL_DOMAIN}
if [ ! -z "${DOMAIN2}" ]; then
    certbot --apache --non-interactive --agree-tos --email admin@${DOMAIN1} -d ${DOMAIN2}
fi
