#!/bin/bash

# CONFIGURA TUS DOMINIOS Y EMAIL AQUI
WORDPRESS_DOMAIN="tu-dominio.com"
PHPMYADMIN_DOMAIN="admin.tu-dominio.com"
EMAIL="tu-email@tudominio.com"

# CREAR ESTRUCTURA DE CARPETAS
mkdir -p wordpress-stack/nginx/conf.d
mkdir -p wordpress-stack/nginx/html

cd wordpress-stack || exit 1

# CREAR DOCKER-COMPOSE
cat <<EOF > docker-compose.yml
version: '3.9'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppassword
    networks:
      - internal
    volumes:
      - wordpress_data:/var/www/html

  db:
    image: mysql:8.0
    container_name: mysql
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword
      MYSQL_ROOT_PASSWORD: rootpassword
    networks:
      - internal
    volumes:
      - db_data:/var/lib/mysql
    command: --default-authentication-plugin=mysql_native_password

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    restart: always
    depends_on:
      - db
    environment:
      PMA_HOST: db
      PMA_USER: root
      PMA_PASSWORD: rootpassword
    networks:
      - internal

  nginx:
    image: nginx:latest
    container_name: nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - certbot-etc:/etc/letsencrypt
      - certbot-var:/var/lib/letsencrypt
      - ./nginx/html:/usr/share/nginx/html
    depends_on:
      - wordpress
      - phpmyadmin
    networks:
      - internal
      - external

  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot-etc:/etc/letsencrypt
      - certbot-var:/var/lib/letsencrypt
      - ./nginx/html:/usr/share/nginx/html
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do sleep 6h & wait \${!}; certbot renew; done'"
    networks:
      - external

volumes:
  wordpress_data:
  db_data:
  certbot-etc:

networks:
  internal:
  external:

# CREAR CONFIG NGINX PARA WORDPRESS
cat <<EOF > nginx/conf.d/wordpress.conf
server {
    listen 80;

    location / {
        proxy_pass http://wordpress:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;

        location /.well-known/acme-challenge/ {
            root /usr/share/nginx/html;
        }
    }
}
EOF

# CREAR CONFIG NGINX PARA PHPMYADMIN
cat <<EOF > nginx/conf.d/phpmyadmin.conf
server {
    listen 80;

    location / {
        proxy_pass http://phpmyadmin:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;

        location /.well-known/acme-challenge/ {
            root /usr/share/nginx/html;
        }
    }
}
EOF

# LEVANTAR LOS SERVICIOS

# ESPERA UNOS SEGUNDOS PARA ESTABILIZAR
echo "Esperando 10 segundos para levantar servicios..."

# OBTENER CERTIFICADOS SSL PARA WORDPRESS
docker-compose run --rm certbot certonly --webroot \
  --webroot-path=/usr/share/nginx/html \
  --email $EMAIL --agree-tos --no-eff-email \
  --domain $WORDPRESS_DOMAIN --domain www.$WORDPRESS_DOMAIN

# OBTENER CERTIFICADOS SSL PARA PHPMYADMIN
docker-compose run --rm certbot certonly --webroot \
  --webroot-path=/usr/share/nginx/html \
  --email $EMAIL --agree-tos --no-eff-email \
  --domain $PHPMYADMIN_DOMAIN

cat <<EOF > nginx/conf.d/wordpress-ssl.conf
server {
    listen 80;
    server_name $WORDPRESS_DOMAIN www.$WORDPRESS_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $WORDPRESS_DOMAIN www.$WORDPRESS_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$WORDPRESS_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$WORDPRESS_DOMAIN/privkey.pem;

    location / {
        proxy_pass http://wordpress:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

cat <<EOF > nginx/conf.d/phpmyadmin-ssl.conf
server {
    listen 80;
    server_name $PHPMYADMIN_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $PHPMYADMIN_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$PHPMYADMIN_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$PHPMYADMIN_DOMAIN/privkey.pem;

    location / {
        proxy_pass http://phpmyadmin:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# REINICIAR NGINX PARA APLICAR HTTPS
docker-compose restart nginx

echo "======================================"
echo "¡DEPLOY COMPLETO!"
echo "WordPress en https://$WORDPRESS_DOMAIN"
echo "phpMyAdmin en https://$PHPMYADMIN_DOMAIN"
echo "======================================"