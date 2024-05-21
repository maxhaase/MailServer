#!/bin/bash
####################################
# Author: maxhaase@gmail.com
#
# This script provisions a mail server with 1 and optionally 2 domains 
# to get you started and nearly done with the setup of a mail server
# with a GUI for webmail and another one to administrate the server; there
# you can add more users, domains and anything you want. 
# It is meant to get the arguments from the ENV that is declared 
# in the Dockerfile. 
#
# Build the Docker Image:
# docker build -t mail_server_image .
#
# Run the Docker Container with 2 domains:
# docker run -d --name mail_server_container -e DOMAIN1=maxhaase.com -e DOMAIN2=example.com -e USER=user -e EMAIL=admin@example.com mail_server_image
#
# To run without a second domain:
# docker run -d --name mail_server_container -e DOMAIN1=maxhaase.com -e USER=user -e EMAIL=admin@maxhaase.com mail_server_image
#
# Enjoy!
#
# /Max
##################################################
# Define variables
DOMAIN1=${DOMAIN1}
DOMAIN2=${DOMAIN2}
USER=${USER}
EMAIL=${EMAIL}
USER_PASSWORD=${USER_PASSWORD}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_POSTFIX_PASSWORD=${MYSQL_POSTFIX_PASSWORD}
MYSQL_POSTFIX_DB=${MYSQL_POSTFIX_DB}
WEBMAIL_DIR="/var/www/roundcube"
POSTFIXADMIN_DIR="/var/www/postfixadmin"
VMAIL_USER="vmail"
VMAIL_UID="5000"
VMAIL_GID="5000"
VMAIL_DIR="/var/mail/vhosts"
PASSWORD_HASH=$(openssl passwd -1 ${USER_PASSWORD})

# Start MySQL service
/etc/init.d/mariadb setup
rc-service mariadb start

# Create vmail user and group if they don't exist
if ! id -u $VMAIL_USER > /dev/null 2>&1; then
    addgroup -g $VMAIL_GID $VMAIL_USER
    adduser -D -u $VMAIL_UID -G $VMAIL_USER -s /sbin/nologin $VMAIL_USER
fi

# Create directories for virtual mailboxes
mkdir -p $VMAIL_DIR/$DOMAIN1/root
mkdir -p $VMAIL_DIR/$DOMAIN1/$USER
if [ -n "$DOMAIN2" ]; then
    mkdir -p $VMAIL_DIR/$DOMAIN2/root
    mkdir -p $VMAIL_DIR/$DOMAIN2/$USER
fi
chown -R $VMAIL_UID:$VMAIL_GID $VMAIL_DIR

# Configure MySQL
mysql_install_db --user=mysql --datadir=/var/lib/mysql
rc-service mariadb start
mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $MYSQL_POSTFIX_DB;"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'postfix'@'localhost' IDENTIFIED BY '$MYSQL_POSTFIX_PASSWORD';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $MYSQL_POSTFIX_DB.* TO 'postfix'@'localhost';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Create Postfix tables in MySQL
mysql -u postfix -p$MYSQL_POSTFIX_PASSWORD $MYSQL_POSTFIX_DB <<EOF
CREATE TABLE domains (
  domain varchar(50) NOT NULL,
  PRIMARY KEY (domain)
);

CREATE TABLE users (
  email varchar(100) NOT NULL,
  password varchar(100) NOT NULL,
  PRIMARY KEY (email)
);

CREATE TABLE aliases (
  alias varchar(100) NOT NULL,
  destination varchar(100) NOT NULL,
  PRIMARY KEY (alias)
);

INSERT INTO domains (domain) VALUES ('$DOMAIN1');
$( [ -n "$DOMAIN2" ] && echo "INSERT INTO domains (domain) VALUES ('$DOMAIN2');" )

INSERT INTO users (email, password) VALUES ('root@$DOMAIN1', '$PASSWORD_HASH');
INSERT INTO users (email, password) VALUES ('$USER@$DOMAIN1', '$PASSWORD_HASH');
$( [ -n "$DOMAIN2" ] && echo "INSERT INTO users (email, password) VALUES ('root@$DOMAIN2', '$PASSWORD_HASH');" )
$( [ -n "$DOMAIN2" ] && echo "INSERT INTO users (email, password) VALUES ('$USER@$DOMAIN2', '$PASSWORD_HASH');" )
EOF

# Configure Postfix to use MySQL
postconf -e "virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf"
postconf -e "virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf"
postconf -e "virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf"
postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"
postconf -e "local_recipient_maps ="

cat <<EOF > /etc/postfix/mysql-virtual-mailbox-domains.cf
user = postfix
password = $MYSQL_POSTFIX_PASSWORD
hosts = 127.0.0.1
dbname = $MYSQL_POSTFIX_DB
query = SELECT domain FROM domains WHERE domain='%s'
EOF

cat <<EOF > /etc/postfix/mysql-virtual-mailbox-maps.cf
user = postfix
password = $MYSQL_POSTFIX_PASSWORD
hosts = 127.0.0.1
dbname = $MYSQL_POSTFIX_DB
query = SELECT email FROM users WHERE email='%s'
EOF

cat <<EOF > /etc/postfix/mysql-virtual-alias-maps.cf
user = postfix
password = $MYSQL_POSTFIX_PASSWORD
hosts = 127.0.0.1
dbname = $MYSQL_POSTFIX_DB
query = SELECT destination FROM aliases WHERE alias='%s'
EOF

# Configure Dovecot to use MySQL
cat <<EOF > /etc/dovecot/dovecot-sql.conf.ext
driver = mysql
connect = host=127.0.0.1 dbname=$MYSQL_POSTFIX_DB user=postfix password=$MYSQL_POSTFIX_PASSWORD
default_pass_scheme = SHA512-CRYPT

password_query = SELECT email as user, password FROM users WHERE email='%u';
user_query = SELECT '$VMAIL_DIR/%d/%n' as home, '$VMAIL_USER' as uid, '$VMAIL_GID' as gid, 'maildir' as mail
EOF

cat <<EOF > /etc/dovecot/conf.d/10-auth.conf
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-sql.conf.ext
EOF

cat <<EOF > /etc/dovecot/conf.d/10-mail.conf
mail_location = maildir:$VMAIL_DIR/%d/%n
namespace inbox {
  inbox = yes
}
EOF

cat <<EOF > /etc/dovecot/conf.d/10-master.conf
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    user = postfix
    group = postfix
    mode = 0600
  }
}
EOF

cat <<EOF > /etc/dovecot/conf.d/10-ssl.conf
ssl = required
ssl_cert = </etc/letsencrypt/live/$DOMAIN1/fullchain.pem
ssl_key = </etc/letsencrypt/live/$DOMAIN1/privkey.pem
EOF

# Obtain Let's Encrypt SSL certificates
certbot certonly --standalone -d $DOMAIN1 $( [ -n "$DOMAIN2" ] && echo "-d $DOMAIN2" ) --agree-tos -m $EMAIL --non-interactive

# Install and configure postfixadmin
cd /var/www/
wget https://github.com/postfixadmin/postfixadmin/archive/postfixadmin-3.3.10.tar.gz
tar xzf postfixadmin-3.3.10.tar.gz
mv postfixadmin-postfixadmin-3.3.10 $POSTFIXADMIN_DIR
chown -R apache:apache $POSTFIXADMIN_DIR
cd $POSTFIXADMIN_DIR
cp config.inc.php config.local.php

sed -i "s/^\(\$CONF\['configured'\] = \).*/\1true;/" config.local.php
sed -i "s/^\(\$CONF\['database_type'\] = \).*/\1'mysqli';/" config.local.php
sed -i "s/^\(\$CONF\['database_host'\] = \).*/\1'localhost';/" config.local.php
sed -i "s/^\(\$CONF\['database_user'\] = \).*/\1'postfix';/" config.local.php
sed -i "s/^\(\$CONF\['database_password'\] = \).*/\1'$MYSQL_POSTFIX_PASSWORD';/" config.local.php
sed -i "s/^\(\$CONF\['database_name'\] = \).*/\1'$MYSQL_POSTFIX_DB';/" config.local.php

# Install and configure Roundcube
wget https://github.com/roundcube/roundcubemail/releases/download/1.5.0/roundcubemail-1.5.0-complete.tar.gz
tar xzf roundcubemail-1.5.0-complete.tar.gz
mv roundcubemail-1.5.0 $WEBMAIL_DIR
chown -R apache:apache $WEBMAIL_DIR
cd $WEBMAIL_DIR
cp config/config.inc.php.sample config/config.inc.php

sed -i "s/^\(\$config\['db_dsnw'\] = \).*/\1'mysql:\/\/postfix:$MYSQL_POSTFIX_PASSWORD@localhost\/$MYSQL_POSTFIX_DB';/" config/config.inc.php
sed -i "s/^\(\$config\['default_host'\] = \).*/\1'localhost';/" config/config.inc.php
sed -i "s/^\(\$config\['smtp_server'\] = \).*/\1'localhost';/" config/config.inc.php

# Configure Apache
cat <<EOF > /etc/apache2/httpd.conf
ServerName localhost

LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
LoadModule dir_module modules/mod_dir.so
LoadModule mime_module modules/mod_mime.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule env_module modules/mod_env.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule status_module modules/mod_status.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule alias_module modules/mod_alias.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule ssl_module modules/mod_ssl.so
LoadModule mime_magic_module modules/mod_mime_magic.so

DocumentRoot "/var/www/localhost/htdocs"

<Directory "/var/www/localhost/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<VirtualHost *:80>
    ServerName $DOMAIN1
    DocumentRoot $WEBMAIL_DIR

    Alias /postfixadmin $POSTFIXADMIN_DIR/public

    <Directory $WEBMAIL_DIR>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>

    <Directory $POSTFIXADMIN_DIR/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>

$( [ -n "$DOMAIN2" ] && echo "
<VirtualHost *:80>
    ServerName $DOMAIN2
    DocumentRoot $WEBMAIL_DIR

    Alias /postfixadmin $POSTFIXADMIN_DIR/public

    <Directory $WEBMAIL_DIR>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>

    <Directory $POSTFIXADMIN_DIR/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
" )
EOF

rc-service apache2 start

# Obtain Let's Encrypt SSL certificates for Apache
certbot --apache -d $DOMAIN1 $( [ -n "$DOMAIN2" ] && echo "-d $DOMAIN2" ) --agree-tos -m $EMAIL --non-interactive

echo "Provisioning completed successfully!"
