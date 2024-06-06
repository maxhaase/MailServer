#!/bin/bash

service mariadb start

# Secure MariaDB installation
mysql -u root <<-EOSQL
  UPDATE mysql.user SET Password=PASSWORD('${MYSQL_ROOT_PASSWORD}') WHERE User='root';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
  FLUSH PRIVILEGES;
EOSQL

mysql -u root -p${MYSQL_ROOT_PASSWORD} <<-EOSQL
  CREATE DATABASE ${MYSQL_DATABASE};
  CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
  GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
  FLUSH PRIVILEGES;
EOSQL

# Enable Apache sites and modules
a2enmod proxy proxy_http ssl
a2ensite mail.DOMAIN1.conf
a2ensite admin.DOMAIN1.conf
a2ensite DOMAIN1.conf
a2ensite DOMAIN2.conf
a2ensite webmail.DOMAIN1.conf

service apache2 restart

# Configure postfixadmin and roundcube
dpkg-reconfigure postfixadmin
dpkg-reconfigure roundcube-core

service postfix start
service dovecot start

# Setup Certbot
certbot --apache --agree-tos --non-interactive --email admin@lung.se -d mail.DOMAIN1 -d admin.DOMAIN1 -d DOMAIN1 -d DOMAIN2 -d webmail.DOMAIN1

# Supervisor
/usr/bin/supervisord -n
