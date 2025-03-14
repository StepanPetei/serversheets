#!/bin/bash
echo "Iniciando servicios..."
docker-compose up -d nginx wordpress phpmyadmin odoo mysql postgres portainer

echo "Esperando 15 segundos para que arranquen los servicios..."
sleep 15

echo "Servicios en marcha."