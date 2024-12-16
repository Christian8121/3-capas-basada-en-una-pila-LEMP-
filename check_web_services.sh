#!/bin/bash

# Funci�n para comprobar el estado de un servicio
check_service() {
    local service_name=$1
    if systemctl is-active --quiet "$service_name"; then
        echo "$service_name est� activo."
    else
        echo "$service_name NO est� activo."
    fi
}

# Comprobar Nginx
echo "Comprobando Nginx..."
check_service nginx

# Comprobar PHP-FPM
echo "Comprobando PHP-FPM..."
check_service php7.4-fpm

sudo apt-get install curl -y
# Comprobar que Nginx puede procesar PHP
echo "Comprobando que Nginx puede procesar PHP..."
if curl -s --head http://192.168.56.10 | grep -q "200 OK"; then
    echo "Nginx est� respondiendo correctamente."
else
    echo "Nginx NO est� respondiendo correctamente."
fi

echo "Comprobaciones completadas para el servidor web."
