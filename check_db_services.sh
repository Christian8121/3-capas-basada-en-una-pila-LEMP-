#!/bin/bash

# Función para comprobar el estado de un servicio
check_service() {
    local service_name=$1
    if systemctl is-active --quiet "$service_name"; then
        echo "$service_name está activo."
    else
        echo "$service_name NO está activo."
    fi
}

# Comprobar MariaDB
echo "Comprobando MariaDB..."
check_service mariadb

# Comprobar conexión a la base de datos
echo "Comprobando conexión a MariaDB..."
if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
    echo "La conexión a MariaDB es exitosa."
else
    echo "La conexión a MariaDB FALLÓ."
fi

echo "Comprobaciones completadas para el servidor de base de datos."
