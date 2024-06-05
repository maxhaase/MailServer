#!/bin/bash

# Start Apache
service apache2 start

# Start MariaDB
service mysql start

# Secure MariaDB installation
mysql -e "UPDATE mysql.user SET Password = PASSWORD('${MYSQL_ROOT_PASSWORD}') WHERE User = 'root'"
mysql -e "DELETE FROM mysql.user WHERE User=''"
mysql -e "DROP DATABASE test"
mysql -e "FLUSH PRIVILEGES"

# Create databases and users
mysql -e "CREATE DATABASE ${MYSQL_DATABASE}"
mysql -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}'"
mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%'"
mysql -e "FLUSH PRIVILEGES"

# Enable Apache sites
a2ensite mail.${DOMAIN1}.conf
a2ensite admin.${DOMAIN1}.conf
a2ensite ${DOMAIN1}.conf
if [ -n "$DOMAIN2" ]; then
  a2ensite ${DOMAIN2}.conf
fi
a2ensite webmail.${DOMAIN1}.conf
a2enmod proxy proxy_http ssl

# Reload Apache
service apache2 reload

# Obtain SSL certificates
certbot --apache -d mail.${DOMAIN1} -d admin.${DOMAIN1} -d ${DOMAIN1} -d ${DOMAIN2} -d webmail.${DOMAIN1} --non-interactive --agree-tos -m admin@${DOMAIN1}

# Start Postfix
service postfix start

# Start Dovecot
service dovecot start

# Keep the container running
tail -f /dev/null
