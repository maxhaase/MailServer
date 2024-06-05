#!/bin/bash

# Start MySQL service
/usr/bin/mysqld_safe --datadir='/var/lib/mysql' &

# Wait for MySQL to start
sleep 10

# Configure MySQL database and users
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
mysql -u root -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Setup WordPress databases
mysql -u root -e "CREATE DATABASE IF NOT EXISTS wordpress_db1;"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS wordpress_db2;"
mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress_db1.* TO 'admin'@'%';"
mysql -u root -e "GR
