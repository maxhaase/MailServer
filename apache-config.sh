#!/bin/bash

# Create Apache configuration files
cat <<EOT > /etc/apache2/sites-available/mail.${DOMAIN1}.conf
<VirtualHost *:80>
    ServerName mail.${DOMAIN1}
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
</VirtualHost>
EOT

cat <<EOT > /etc/apache2/sites-available/admin.${DOMAIN1}.conf
<VirtualHost *:80>
    ServerName admin.${DOMAIN1}
    ProxyPreserveHost On
    ProxyPass / http://localhost:8081/
    ProxyPassReverse / http://localhost:8081/
</VirtualHost>
EOT

cat <<EOT > /etc/apache2/sites-available/${DOMAIN1}.conf
<VirtualHost *:80>
    ServerName ${DOMAIN1}
    ProxyPreserveHost On
    ProxyPass / http://localhost:8001/
    ProxyPassReverse / http://localhost:8001/
</VirtualHost>
EOT

cat <<EOT > /etc/apache2/sites-available/${DOMAIN2}.conf
<VirtualHost *:80>
    ServerName ${DOMAIN2}
    ProxyPreserveHost On
    ProxyPass / http://localhost:8002/
    ProxyPassReverse / http://localhost:8002/
</VirtualHost>
EOT

cat <<EOT > /etc/apache2/sites-available/webmail.${DOMAIN1}.conf
<VirtualHost *:80>
    ServerName webmail.${DOMAIN1}
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
</VirtualHost>
EOT

# Enable Apache sites
a2ensite mail.${DOMAIN1}.conf
a2ensite admin.${DOMAIN1}.conf
a2ensite ${DOMAIN1}.conf
if [ ! -z "${DOMAIN2}" ]; then
  a2ensite ${DOMAIN2}.conf
fi
a2ensite webmail.${DOMAIN1}.conf

# Reload Apache to apply configurations
systemctl reload apache2

# Request SSL Certificates
certbot --apache -d mail.${DOMAIN1} -d admin.${DOMAIN1} -d ${DOMAIN1} -d webmail.${DOMAIN1} -d ${DOMAIN2} --non-interactive --agree-tos --email admin@${DOMAIN1}
