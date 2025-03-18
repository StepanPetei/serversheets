docker-compose run --rm certbot certonly --webroot \
  --webroot-path=/usr/share/nginx/html \
  --email tu-email@tudominio.com --agree-tos --no-eff-email \
  -d tu-dominio.com -d www.tu-dominio.com

docker-compose run --rm certbot certonly --webroot \
  --webroot-path=/usr/share/nginx/html \
  --email tu-email@tudominio.com --agree-tos --no-eff-email \
  -d admin.tu-dominio.com