#!/bin/bash

# Apache virtual hosts configuration
cat <<EOT > /etc/apache2/sites-available/mail.\$DOMAIN1.conf
<VirtualHost *:80>
    ServerName mail.\$DOMAIN1
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
</VirtualHost>
EOT

cat <<EOT > /etc/apache2/sites-available/admin.\$DOMAIN1.conf
<VirtualHost *:80>
    ServerName admin.\$DOMAIN1
    ProxyPreserveHost On
    ProxyPass / http://localhost:8081/
    ProxyPassReverse / http://localhost:8081/
</VirtualHost>
EOT

cat <<EOT > /etc/apache2/sites-available/\$DOMAIN1.conf
<VirtualHost *:80>
    ServerName \$DOMAIN1
    ProxyPreserveHost On
    ProxyPass / http://localhost:8001/
    ProxyPassReverse / http://localhost:8001/
</VirtualHost>
EOT

cat <<EOT > /etc/apache2/sites-available/\$DOMAIN2.conf
<VirtualHost *:80>
    ServerName \$DOMAIN2
    ProxyPreserveHost On
    ProxyPass / http://localhost:8002/
    ProxyPassReverse / http://localhost:8002/
</VirtualHost>
EOT

cat <<EOT > /etc/apache2/sites-available/webmail.\$DOMAIN1.conf
<VirtualHost *:80>
    ServerName webmail.\$DOMAIN1
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
</VirtualHost>
EOT

# Enable sites
a2ensite mail.\$DOMAIN1.conf
a2ensite admin.\$DOMAIN1.conf
a2ensite \$DOMAIN1.conf
if [ ! -z "\$DOMAIN2" ]; then
    a2ensite \$DOMAIN2.conf
fi
a2ensite webmail.\$DOMAIN1.conf

# Enable necessary modules
a2enmod proxy
a2enmod proxy_http
a2enmod ssl

# Restart Apache to apply changes
systemctl restart apache2
