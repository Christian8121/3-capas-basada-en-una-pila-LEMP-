#!/bin/bash

# Comprobación del estado de Nginx
if systemctl is-active --quiet nginx; then
    echo "Nginx está funcionando correctamente."
else
    echo "Error: Nginx no está funcionando."
fi

# Comprobación del estado de PHP-FPM
if systemctl is-active --quiet php7.4-fpm; then
    echo "PHP-FPM 7.4 está funcionando correctamente."
else
    echo "Error: PHP-FPM 7.4 no está funcionando."
fi

# Comprobación de montaje de la carpeta NFS
MOUNT_POINT="/var/www/html"
if mountpoint -q "$MOUNT_POINT"; then
    echo "La carpeta NFS está montada en $MOUNT_POINT."
else
    echo "Error: La carpeta NFS no está montada en $MOUNT_POINT."
fi
