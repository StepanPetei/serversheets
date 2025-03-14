#!/bin/bash

EMAIL="tu-email@tudominio.com"
DOMINIOS=(
  "tu-dominio.com"
    "www.tu-dominio.com"
      "admin.tu-dominio.com"
        "erp.tu-dominio.com"
          "portainer.tu-dominio.com"
          )

          for domain in "${DOMINIOS[@]}"; do
            echo "Generando certificado para $domain..."
              docker-compose run --rm certbot certonly --webroot \
                  --webroot-path=/usr/share/nginx/html \
                      --email $EMAIL --agree-tos --no-eff-email \
                          -d $domain
                          done

                          echo "Certificados generados."