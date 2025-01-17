#!/bin/bash

# Comprobación del estado de MariaDB
if systemctl is-active --quiet mariadb; then
    echo "MariaDB está funcionando correctamente."
else
    echo "Error: MariaDB no está funcionando."
fi

# Comprobación de la configuración de acceso remoto en MariaDB
CONFIG_FILE="/etc/mysql/mariadb.conf.d/50-server.cnf"
if grep -q "bind-address = 192.168.60.10" "$CONFIG_FILE"; then
    echo "La configuración de MariaDB permite acceso remoto desde 192.168.60.10."
else
    echo "Error: La configuración de acceso remoto no está correctamente configurada en MariaDB."
fi

# Comprobación de la existencia de la base de datos de OwnCloud
DB_EXISTS=$(mysql -u root -e "SHOW DATABASES LIKE 'owncloud';" | grep -c "owncloud")
if [ "$DB_EXISTS" -eq 1 ]; then
    echo "La base de datos 'owncloud' existe."
else
    echo "Error: La base de datos 'owncloud' no existe."
fi

# Comprobación de la existencia del usuario de OwnCloud
USER_EXISTS=$(mysql -u root -e "SELECT User FROM mysql.user WHERE User='owncloud';" | grep -c "owncloud")
if [ "$USER_EXISTS" -eq 1 ]; then
    echo "El usuario 'owncloud' está configurado correctamente."
else
    echo "Error: El usuario 'owncloud' no está configurado."
fi

# Comprobación de los privilegios del usuario de OwnCloud
PRIVILEGES=$(mysql -u root -e "SHOW GRANTS FOR 'owncloud'@'192.168.60.%';" | grep -c "GRANT ALL PRIVILEGES ON `owncloud`.* TO 'owncloud'@'192.168.60.%'")
if [ "$PRIVILEGES" -eq 1 ]; then
    echo "El usuario 'owncloud' tiene los privilegios necesarios sobre la base de datos 'owncloud'."
else
    echo "Error: El usuario 'owncloud' no tiene los privilegios necesarios sobre la base de datos 'owncloud'."
fi
