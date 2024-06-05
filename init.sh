#!/bin/bash

# Start MySQL service
/usr/bin/mysqld_safe --datadir='/var/lib/mysql' &

# Wait for MySQL to start
sleep 10

# Configure MySQL database and users
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"

# Setup WordPress databases
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS wordpress_db1;"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS wordpress_db2;"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON wordpress_db1.* TO '${MYSQL_USER}'@'%';"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON wordpress_db2.* TO '${MYSQL_USER}'@'%';"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"

# Setup PostfixAdmin
php /var/www/html/postfixadmin/public/setup.php

# Setup Roundcube
php /var/www/html/roundcubemail/bin/initdb.sh --dir=/var/www/html/roundcubemail/SQL --create
php /var/www/html/roundcubemail/bin/update.sh --dir=/var/www/html/roundcubemail/SQL

# Setup WordPress
php /var/www/html/wordpress/wp-admin/install.php

# Start all services
supervisord -c /etc/supervisord.conf
