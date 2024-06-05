#!/bin/bash

# Start MySQL
service mysql start

# Secure MySQL installation
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE ${MYSQL_DATABASE};
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Configure Apache
a2ensite mail.example1.com.conf admin.example1.com.conf webmail.example1.com.conf DOMAIN1.conf DOMAIN2.conf
a2enmod proxy proxy_http ssl

# Start services
service apache2 restart
service postfix start
service dovecot start
service supervisor start

# Keep the container running
tail -f /dev/null
