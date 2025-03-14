#!/bin/bash

# Variables
SSL_DIR="/etc/ssl"
PRIVATE_KEY="$SSL_DIR/private/mysslkey.key"
CSR_FILE="$SSL_DIR/csr/myssl.csr"
CERT_FILE="$SSL_DIR/certs/mysslcert.crt"
VPN_CONFIG_DIR="/etc/openvpn"
DOCKER_CONTAINER_NAME="web-container"
DOCKER_PORT=8080

# 1. Instalar dependencias necesarias
echo "Instalando dependencias..."
sudo apt update
sudo apt install -y openvpn easy-rsa docker.io

# 2. Configuración del firewall UFW
echo "Configurando firewall UFW..."
sudo ufw enable
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw limit 22/tcp
sudo ufw status verbose

# 3. Generación de certificado SSL autofirmado
echo "Generando certificado SSL autofirmado..."
sudo mkdir -p $SSL_DIR/private $SSL_DIR/csr $SSL_DIR/certs
sudo openssl genpkey -algorithm RSA -out $PRIVATE_KEY -pkeyopt rsa_keygen_bits:2048
sudo openssl req -new -key $PRIVATE_KEY -out $CSR_FILE
sudo openssl x509 -req -in $CSR_FILE -signkey $PRIVATE_KEY -out $CERT_FILE -days 365
echo "Certificado SSL generado en: $CERT_FILE"

# 4. Configuración de Nginx con el certificado SSL autofirmado
echo "Configurando Nginx con SSL..."
#sudo apt install -y nginx
sudo tee /etc/nginx/sites-available/default <<EOF
server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate $CERT_FILE;
    ssl_certificate_key $PRIVATE_KEY;

    location / {
        root /var/www/html;
        index index.html;
    }
}

server {
    listen 80;
    server_name localhost;

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

sudo systemctl restart nginx

# 5. Configuración de OpenVPN
echo "Configurando OpenVPN..."
cd /etc/openvpn
sudo make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
source ./vars
./clean-all
./build-ca
./build-key-server server
./build-dh
./build-key client
./generate-server-config
echo "Configuración de OpenVPN generada en /etc/openvpn/easy-rsa"

# 6. Configuración de Docker para aislamiento de servicios
echo "Configurando Docker..."
sudo systemctl start docker
sudo systemctl enable docker
sudo docker run -d -p $DOCKER_PORT:80 --name $DOCKER_CONTAINER_NAME nginx
echo "Contenedor Docker de Nginx corriendo en el puerto $DOCKER_PORT"

# 7. Configuración de cron para renovación automática de certificados
echo "Configurando renovación automática de certificados..."
sudo crontab -l > mycron
echo "0 0,12 * * * certbot renew --quiet" >> mycron
sudo crontab mycron
rm mycron

echo "Configuración de homelab completada!"