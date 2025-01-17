#!/bin/bash

# Comprobación del estado de NFS
if systemctl is-active --quiet nfs-kernel-server; then
    echo "NFS está funcionando correctamente."
else
    echo "Error: NFS no está funcionando."
fi

# Comprobación del estado de PHP-FPM
if systemctl is-active --quiet php7.4-fpm; then
    echo "PHP-FPM 7.4 está funcionando correctamente."
else
    echo "Error: PHP-FPM 7.4 no está funcionando."
fi

# Comprobación de la carpeta compartida por NFS
EXPORTS_FILE="/etc/exports"
if grep -q "/var/www/html" "$EXPORTS_FILE"; then
    echo "La carpeta /var/www/html está configurada correctamente en /etc/exports."
else
    echo "Error: La carpeta /var/www/html no está configurada en /etc/exports."
fi

# Comprobación de montaje de la carpeta compartida NFS
MOUNT_POINT="/var/www/html"
if mountpoint -q "$MOUNT_POINT"; then
    echo "La carpeta compartida está montada correctamente en $MOUNT_POINT."
else
    echo "Error: La carpeta compartida no está montada en $MOUNT_POINT."
fi

# Comprobación de OwnCloud en la carpeta compartida
if [ -d "/var/www/html/owncloud" ]; then
    echo "OwnCloud está instalado correctamente en /var/www/html/owncloud."
else
    echo "Error: OwnCloud no está instalado en /var/www/html/owncloud."
fi

# Comprobación del archivo de configuración inicial de OwnCloud
if [ -f "/var/www/html/owncloud/config/autoconfig.php" ]; then
    echo "El archivo de configuración inicial de OwnCloud existe."
else
    echo "Error: El archivo de configuración inicial de OwnCloud no existe."
fi

# Comprobación de los dominios de confianza en OwnCloud
CONFIG_FILE="/var/www/html/owncloud/config/config.php"
if [ -f "$CONFIG_FILE" ]; then
    if grep -q "'trusted_domains'" "$CONFIG_FILE"; then
        echo "Los dominios de confianza están configurados en OwnCloud."
    else
        echo "Error: Los dominios de confianza no están configurados en OwnCloud."
    fi
else
    echo "Error: No se encontró el archivo config.php de OwnCloud."
fi
