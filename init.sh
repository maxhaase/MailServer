#!/bin/bash

# Start services
service mysql start
service apache2 start
service postfix start
service dovecot start
service supervisor start

# Configure MySQL
mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
mysql -e "FLUSH PRIVILEGES;"

# Enable Apache sites
a2ensite ${MAIL_DOMAIN}.conf
a2ensite ${ADMIN_DOMAIN}.conf
a2ensite ${DOMAIN1}.conf
a2ensite ${DOMAIN2}.conf
a2ensite ${WEBMAIL_DOMAIN}.conf

# Get SSL certificates
certbot --apache --non-interactive --agree-tos --email admin@${DOMAIN1} -d ${DOMAIN1} -d ${DOMAIN2} -d ${MAIL_DOMAIN} -d ${ADMIN_DOMAIN} -d ${WEBMAIL_DOMAIN}

# Restart Apache to apply changes
service apache2 restart

# Keep container running
tail -f /var/log/apache2/access.log
