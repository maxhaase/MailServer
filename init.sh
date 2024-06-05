#!/bin/bash

# Start MySQL service
service mysql start

# Configure MySQL
mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Enable Apache modules and sites
a2enmod proxy proxy_http ssl
a2ensite admin.${DOMAIN1}.conf webmail.${DOMAIN1}.conf ${DOMAIN1}.conf ${DOMAIN2}.conf
a2enconf roundcube postfixadmin

# Enable and start services
service apache2 start
service postfix start
service dovecot start
service supervisor start

# Obtain SSL certificates
certbot --apache -d ${DOMAIN1} -d ${DOMAIN2} -d admin.${DOMAIN1} -d webmail.${DOMAIN1}

# Keep container running
tail -f /var/log/apache2/access.log
