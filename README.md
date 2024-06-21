
# Comprehensive Guide to Setting Up Mail Server and Web Services with Docker, Apache, and SSL on Ubuntu 24

## You should consider the AWS Kubernetes in MaxOffice, is a bit less easy, but better, and like always, free! 

## Step 1: Prepare the Environment

### Update and Install Prerequisites:
```sh
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose apache2 certbot python3-certbot-apache vim
```

### Add User to Docker Group:
```sh
sudo usermod -aG docker busy
```

### Create Docker Directory and Adjust Permissions:
```sh
sudo mkdir -p /docker
sudo chown -R busy:busy /docker
cd /docker
```

## Step 2: Setup Docker Compose Environment

### Create `.env` File:
```sh
cat <<EOT > .env
MYSQL_ROOT_PASSWORD=ChangeMe
MYSQL_USER=admin
MYSQL_PASSWORD=ChangeMe
MYSQL_DATABASE=mailserver_db
WORDPRESS_DB_USER=admin
WORDPRESS_DB_PASSWORD=ChangeMe
POSTFIXADMIN_SETUP_PASSWORD=ChangeMe
ROUNDCUBEMAIL_DB_USER=admin
ROUNDCUBEMAIL_DB_PASSWORD=ChangeMe
DOMAIN1=example1.com
DOMAIN2=example2.com
MAIL_DOMAIN=mail.example1.com
ADMIN_DOMAIN=admin.example1.com
WEBMAIL_DOMAIN=webmail.example1.com
EOT
```

### Create `docker-compose.yml` file:
```sh
vim docker-compose.yml
```

Add the following content then save and close the file:
```yaml
version: '3.7'

services:
  db:
    image: mariadb:latest
    volumes:
      - db_data:/var/lib/mysql
    env_file:
      - .env
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
    ports:
      - "3306:3306"

  postfix:
    image: boky/postfix
    env_file:
      - .env
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
    ports:
      - "25:25"
      - "587:587"

  dovecot:
    image: tvial/docker-mailserver:latest
    env_file:
      - .env
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
    ports:
      - "993:993"
      - "995:995"

  postfixadmin:
    image: postfixadmin
    volumes:
      - postfixadmin_data:/data
    env_file:
      - .env
    environment:
      POSTFIXADMIN_SETUP_PASSWORD: \${POSTFIXADMIN_SETUP_PASSWORD}
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
    ports:
      - "8081:80"

  roundcube:
    image: roundcube/roundcubemail
    env_file:
      - .env
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
    ports:
      - "8080:80"

  wordpress_domain1:
    image: wordpress:latest
    volumes:
      - wordpress_domain1_data:/var/www/html
    env_file:
      - .env
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: \${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: \${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
    ports:
      - "8001:80"

  wordpress_domain2:
    image: wordpress:latest
    volumes:
      - wordpress_domain2_data:/var/www/html
    env_file:
      - .env
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: \${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: \${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
    ports:
      - "8002:80"

volumes:
  db_data:
  postfixadmin_data:
  wordpress_domain1_data:
  wordpress_domain2_data:
```

### Bring Up Docker Compose Services:
```sh
docker-compose up -d
```

## Step 3: Configure Apache as a Reverse Proxy and Create Apache Configuration for Each Site

```sh
sudo a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests ssl
cat <<EOT | sudo tee /etc/apache2/sites-available/mail.example1.com.conf
<VirtualHost *:80>
    ServerName mail.example1.com
    ProxyPreserveHost On
    ProxyPass / http://localhost:8081/
    ProxyPassReverse / http://localhost:8081/
</VirtualHost>
EOT

cat <<EOT | sudo tee /etc/apache2/sites-available/admin.example1.com.conf
<VirtualHost *:80>
    ServerName admin.example1.com
    ProxyPreserveHost On
    ProxyPass / http://localhost:8081/
    ProxyPassReverse / http://localhost:8081/
</VirtualHost>
EOT

cat <<EOT | sudo tee /etc/apache2/sites-available/example1.com.conf
<VirtualHost *:80>
    ServerName example1.com
    ProxyPreserveHost On
    ProxyPass / http://localhost:8001/
    ProxyPassReverse / http://localhost:8001/
</VirtualHost>
EOT

cat <<EOT | sudo tee /etc/apache2/sites-available/example2.com.conf
<VirtualHost *:80>
    ServerName example2.com
    ProxyPreserveHost On
    ProxyPass / http://localhost:8002/
    ProxyPassReverse / http://localhost:8002/
</VirtualHost>
EOT

cat <<EOT | sudo tee /etc/apache2/sites-available/webmail.example1.com.conf
<VirtualHost *:80>
    ServerName webmail.example1.com
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
</VirtualHost>
EOT
```

### Enable Sites and Restart Apache:
```sh
sudo a2ensite mail.example1.com.conf
sudo a2ensite admin.example1.com.conf
sudo a2ensite example1.com.conf
sudo a2ensite example2.com.conf
sudo a2ensite webmail.example1.com.conf
sudo systemctl restart apache2
```

## Step 4: Request SSL Certificates

```sh
sudo certbot --apache -d mail.example1.com -d admin.example1.com -d example1.com -d example2.com -d webmail.example1.com --cert-name mail.example1.com --key-type rsa
```

## Step 5: Setup Automatic Backups

### Create Backup Script:
```sh
cat <<EOT > /docker/tools/backup.sh
#!/bin/bash
BACKUP_DIR="/SPACE/BACKUP/database"
TIMESTAMP=$(date +%F-%H-%M-%S)
docker exec db /usr/bin/mysqldump -u root --password=\${MYSQL_ROOT_PASSWORD} \${MYSQL_DATABASE} > \${BACKUP_DIR}/database_\${TIMESTAMP}.sql
tar -czf \${BACKUP_DIR}/database_\${TIMESTAMP}.tar.gz -C \${BACKUP_DIR} database_\${TIMESTAMP}.sql
rm \${BACKUP_DIR}/database_\${TIMESTAMP}.sql
EOT
```

### Make Backup Script Executable:
```sh
chmod +x /docker/tools/backup.sh
```

### Setup Cron Job:
```sh
(crontab -l 2>/dev/null; echo "0 3 * * * /docker/tools/backup.sh") | crontab -
```

## Summary

By following these steps, you will have a fully functional mail server and web services setup using Docker and Apache with SSL. This comprehensive guide ensures that you have a secure and maintainable system for managing your domains and services.

Make sure you replace example1.com and example2.com with your actual domain names before running the commands.

# Update DNS Records
Taking in consideration that the domains exist and the default values are already there, these examples can help you setup what you'll need. 
Notice that you could host the web servers and everything on the same host, but that is not recommended, instead you should use another docker and 
add it to the orchestration. Use the WordPress code in the project to create 1 or 2 WordPress sites and wrap it all up with Kubernetes.

##########################################<br>
A Record for mail.example.com:<br>
Name: mail<br>
Type: A<br>
IP Address: The public IP address of your mail server<br><br>

MX: @ 10 mail.example.com<br>
A: mail The public IP address of your mail server<br>

Name: email<br>
Type: CNAME<br>
Value: mail.example.com.<br>

Name: TXT<br>
Type: @<br>
Value: v=spf1 a mx ip4:The public IP address of your mail server ~all<br>

Name: TXT<br>
Type: @	<br>
Value: mail._domainkey IN TXT ( "v=DKIM1; h=rsa-sha256; k=rsa; s=email; " "p=THE PUBLIC KEY OF YOUR MAIL SERVER" ) ; ----- DKIM key mail for mail.example.com<br>

Name: TXT<br>
Type: PRT<br>
Value: For improved security, you should have a reverse lookup record. If you don't have your own DNS server, you might have to ask your host provider to help you. <br>
If they refuse, then you can create your DNS server container to get around that.

##########################################<br>
MX Record for example1.com:<br>
Name: @<br>
Type: MX<br>
Priority: 10 (or any other appropriate value)<br>
Mail Server: mail.example.com<br>

##########################################<br>
MX Record for example2.com:<br>
Name: @<br>
Type: MX<br>
Priority: 10 (or any other appropriate value)<br>
Mail Server: mail.example.com<br>
