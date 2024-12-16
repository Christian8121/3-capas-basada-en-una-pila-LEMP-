#!/bin/bash

# Actualizar el sistema
sudo apt update -y && sudo apt upgrade -y

# Instalar dependencias necesarias para agregar el repositorio de PHP
sudo apt install -y lsb-release apt-transport-https ca-certificates wget bzip2

# Agregar el repositorio de PHP 7.4
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

# Actualizar la lista de paquetes después de agregar el nuevo repositorio
sudo apt update

# Instalar NFS y PHP-FPM con versión 7.4
sudo apt install -y nfs-kernel-server nfs-common php7.4-fpm php7.4-imagick php7.4-common php7.4-curl php7.4-gd php7.4-intl php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-pgsql php7.4-ssh2 php7.4-sqlite3 php7.4-xml php7.4-zip

# Crear y exportar el directorio compartido
sudo mkdir -p /var/nfs/shared/
sudo chown -R www-data:www-data /var/nfs/shared/

# Ajustar permisos después de descomprimir
sudo chmod -R 775 /var/nfs/shared/ # Permitir lectura y escritura para el grupo
# Eliminar la entrada existente si está presente
if grep -q "/var/nfs/shared" /etc/exports; then
    echo "Eliminando la entrada existente en /etc/exports..."
    sudo sed -i.bak "/\/var\/nfs\/shared/d" /etc/exports
fi

# Agregar la nueva entrada al archivo /etc/exports
EXPORT_ENTRY="/var/nfs/shared 192.168.56.0/24(rw,sync,no_root_squash,no_subtree_check)"
echo "$EXPORT_ENTRY" | sudo tee -a /etc/exports

# Actualizar las exportaciones de NFS
sudo exportfs -a

# Descargar e instalar OwnCloud
OWNCLOUD_TAR="owncloud-complete-latest.tar.bz2"
if ! wget -q "https://download.owncloud.com/server/stable/$OWNCLOUD_TAR"; then
    echo "Error al descargar OwnCloud."
    exit 1
fi

# Verificar si el archivo se descargó correctamente antes de descomprimir
if [ ! -f "$OWNCLOUD_TAR" ]; then
    echo "El archivo $OWNCLOUD_TAR no se encontró."
    exit 1
fi

# Descomprimir el archivo tar.bz2 en la carpeta correcta
if ! sudo tar -xjf "$OWNCLOUD_TAR" -C /var/nfs/shared/; then
    echo "Error al descomprimir OwnCloud."
    exit 1
fi

# Instalar UFW si no está instalado
if ! command -v ufw &> /dev/null; then
    sudo apt install -y ufw
fi

# Configuración inicial del firewall: Permitir SSH
sudo ufw allow ssh

# Establecer políticas predeterminadas para denegar todas las conexiones entrantes y permitir las salientes
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir el puerto 2049 para NFS con persistencia
sudo ufw allow 2049/tcp

# Habilitar el firewall automáticamente sin confirmación
sudo ufw --force enable

# Reiniciar servicios NFS y PHP-FPM
if ! sudo systemctl restart nfs-kernel-server; then
    echo "Error al reiniciar NFS, verifica si está instalado correctamente."
    exit 1
fi

sudo systemctl enable nfs-kernel-server

if ! sudo systemctl restart php7.4-fpm; then
    echo "Error al reiniciar PHP-FPM, verifica si está instalado correctamente."
    exit 1
fi

sudo systemctl enable php7.4-fpm

echo "Instalación de OwnCloud completada con éxito."

# En caso de querer reestablecer el owncloud y crear un nuevo admin
# sudo rm /var/nfs/shared/owncloud/config/config.php
