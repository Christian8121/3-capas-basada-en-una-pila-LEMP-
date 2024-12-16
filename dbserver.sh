#!/bin/bash

# Actualizar el sistema
sudo apt update -y && sudo apt upgrade -y

# Instalar MariaDB
sudo apt install -y mariadb-server

# Configurar MariaDB para aceptar conexiones remotas
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Reiniciar MariaDB para aplicar cambios
sudo systemctl restart mariadb

# Asegurarse de que MariaDB esté habilitado para iniciar al arranque
sudo systemctl enable mariadb

# Crear la base de datos y el usuario para OwnCloud
sudo mysql -u root <<EOF
CREATE DATABASE owncloud_db;
CREATE USER 'owncloud_user'@'%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON owncloud_db.* TO 'owncloud_user'@'%';
FLUSH PRIVILEGES;
EOF

# Instalar UFW si no está instalado
if ! command -v ufw &> /dev/null; then
    sudo apt install -y ufw
fi

# Configuración inicial del firewall: Permitir SSH
sudo ufw allow ssh

# Establecer políticas predeterminadas para denegar todas las conexiones entrantes y permitir las salientes
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir el puerto 3306 para MariaDB con persistencia
sudo ufw allow 3306/tcp

# Habilitar el firewall
sudo ufw --force enable

# Recargar UFW para aplicar los cambios (opcional)
sudo ufw reload
