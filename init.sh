#!/bin/bash

# Start MariaDB service
service mysql start

# Set up the database
mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

# Configure PostfixAdmin
debconf-set-selections <<< "postfixadmin postfixadmin/dbconfig-install boolean true"
debconf-set-selections <<< "postfixadmin postfixadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "postfixadmin postfixadmin/mysql/app-pass password $MYSQL_PASSWORD"
debconf-set-selections <<< "postfixadmin postfixadmin/mysql/admin-user string root"
debconf-set-selections <<< "postfixadmin postfixadmin/db/dbname string $MYSQL_DATABASE"
debconf-set-selections <<< "postfixadmin postfixadmin/db/app-user string $MYSQL_USER"
debconf-set-selections <<< "postfixadmin postfixadmin/app-password-confirm password $MYSQL_PASSWORD"
debconf-set-selections <<< "postfixadmin postfixadmin/password-confirm password $MYSQL_PASSWORD"

# Configure Roundcube
debconf-set-selections <<< "roundcube-core roundcube/dbconfig-install boolean true"
debconf-set-selections <<< "roundcube-core roundcube/mysql/admin-pass password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "roundcube-core roundcube/mysql/app-pass password $MYSQL_PASSWORD"
debconf-set-selections <<< "roundcube-core roundcube/mysql/admin-user string root"
debconf-set-selections <<< "roundcube-core roundcube/db/dbname string $MYSQL_DATABASE"
debconf-set-selections <<< "roundcube-core roundcube/db/app-user string $MYSQL_USER"
debconf-set-selections <<< "roundcube-core roundcube/app-password-confirm password $MYSQL_PASSWORD"
debconf-set-selections <<< "roundcube-core roundcube/password-confirm password $MYSQL_PASSWORD"

# Enable Apache sites and SSL
a2ensite mail.DOMAIN1.conf
a2ensite admin.DOMAIN1.conf
a2ensite DOMAIN1.conf
a2ensite DOMAIN2.conf
a2enmod ssl
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite
a2enmod headers

# Obtain SSL certificates
certbot --apache -d $MAIL_DOMAIN -d $ADMIN_DOMAIN -d $DOMAIN1 -d $DOMAIN2 -d $WEBMAIL_DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN1

# Restart services to apply changes
service apache2 restart
service postfix restart
service dovecot restart
service mysql restart

# Keep the container running
tail -f /dev/null
