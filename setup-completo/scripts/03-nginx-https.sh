#!/bin/bash

DOMAINS=(
  "tu-dominio.com"
    "admin.tu-dominio.com"
      "erp.tu-dominio.com"
        "portainer.tu-dominio.com"
        )

        # Wordpress HTTPS config
        cat <<EOF > ../nginx/conf.d/wordpress.conf
        server {
            listen 80;
                server_name tu-dominio.com www.tu-dominio.com;
                    return 301 https://\$host\$request_uri;
                    }

                    server {
                        listen 443 ssl;
                            server_name tu-dominio.com www.tu-dominio.com;

                                ssl_certificate /etc/letsencrypt/live/tu-dominio.com/fullchain.pem;
                                    ssl_certificate_key /etc/letsencrypt/live/tu-dominio.com/privkey.pem;

                                        location / {
                                                proxy_pass http://wordpress:80;
                                                        proxy_set_header Host \$host;
                                                                proxy_set_header X-Real-IP \$remote_addr;
                                                                    }
                                                                    }
                                                                    EOF

                                                                    # Repite para cada servicio...

                                                                    echo "Reiniciando NGINX para aplicar HTTPS..."
                                                                    docker-compose restart nginx