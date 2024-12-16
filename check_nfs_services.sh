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

# Comprobar NFS Server
echo "Comprobando NFS Server..."
check_service nfs-kernel-server

# Comprobar si el directorio compartido está exportado correctamente
echo "Comprobando exportaciones NFS..."
if exportfs | grep -q "/var/nfs/shared"; then
    echo "El directorio NFS está exportado correctamente."
else
    echo "El directorio NFS NO está exportado."
fi

echo "Comprobaciones completadas para el servidor NFS."
