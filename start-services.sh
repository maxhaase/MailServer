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
a2ensite mail.conf admin.conf webmail.conf wordpress1.conf wordpress2.conf
a2enmod proxy proxy_http ssl

# Start services
service apache2 restart
service postfix start
service dovecot start
service supervisor start

# Keep the container running
tail -f /dev/null
