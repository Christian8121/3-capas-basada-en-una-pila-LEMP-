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

# Comprobar MariaDB
echo "Comprobando MariaDB..."
check_service mariadb

# Comprobar conexi�n a la base de datos
echo "Comprobando conexi�n a MariaDB..."
if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
    echo "La conexi�n a MariaDB es exitosa."
else
    echo "La conexi�n a MariaDB FALL�."
fi

echo "Comprobaciones completadas para el servidor de base de datos."
