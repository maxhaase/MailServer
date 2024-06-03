version: '3.7'

services:
  db:
    image: mariadb:10.5
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

