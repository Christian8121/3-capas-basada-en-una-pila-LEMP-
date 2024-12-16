#!/bin/bash

# Actualizar el sistema
sudo apt update -y && sudo apt upgrade -y

# Instalar dependencias necesarias para agregar el repositorio de PHP
sudo apt install -y lsb-release apt-transport-https ca-certificates wget

# Agregar el repositorio de PHP 7.4
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

# Actualizar la lista de paquetes después de agregar el nuevo repositorio
sudo apt update

# Instalar Nginx y módulos PHP necesarios (sin smbclient)
sudo apt install -y nginx php7.4-fpm php7.4-imagick php7.4-common php7.4-curl php7.4-gd php7.4-intl php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-pgsql php7.4-ssh2 php7.4-sqlite3 php7.4-xml php7.4-zip unzip nfs-common

# Montar la carpeta compartida desde el servidor NFS (si no está montada)
MOUNT_POINT="/var/www/owncloud"
if ! mountpoint -q "$MOUNT_POINT"; then
    sudo mkdir -p "$MOUNT_POINT"
    if ! sudo mount -t nfs 192.168.56.30:/var/nfs/shared/owncloud "$MOUNT_POINT"; then
        echo "Error al montar el NFS, verifica que el servidor NFS esté funcionando y la ruta sea correcta."
        exit 1
    fi
fi

# Es imprescindible cambiar los permisos de las carpetas data y apps-external
# Cambia a la carpeta de OwnCloud
# cd /var/www/owncloud

# Cambia el propietario del directorio data y apps-external a www-data
# sudo chown -R www-data:www-data data/
# sudo chown -R www-data:www-data apps-external/

# Ajusta los permisos para permitir lectura y escritura
# sudo chmod -R 775 data/
# sudo chmod -R 775 apps-external/

# Configurar persistencia del montaje en fstab si no está configurado ya
if ! grep -qs "192.168.56.30:/var/nfs/shared/owncloud" /etc/fstab; then
    echo "192.168.56.30:/var/nfs/shared/owncloud /var/www/owncloud nfs defaults 0 0" | sudo tee -a /etc/fstab
fi

# Configurar Nginx para OwnCloud
cat <<EOF | sudo tee /etc/nginx/sites-available/owncloud
server {
    listen 80;
    server_name 192.168.56.21;

    root /var/www/owncloud;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; 
        include fastcgi_params; 
    }

    location ~ /\.ht {
        deny all;
    }
}

EOF

# Enlazar la configuración de OwnCloud y reiniciar Nginx
# Definir las rutas
SOURCE="/etc/nginx/sites-available/owncloud"
LINK="/etc/nginx/sites-enabled/owncloud"

# Comprobar si el archivo fuente existe
if [ -f "$SOURCE" ]; then
    # Si el enlace simbólico ya existe, eliminarlo
    if [ -L "$LINK" ]; then
        echo "Eliminando el enlace simbólico existente: $LINK"
        sudo rm "$LINK"
    fi

    # Crear el nuevo enlace simbólico
    sudo ln -s "$SOURCE" "$LINK"
    echo "Enlace simbólico creado: $LINK -> $SOURCE"
else
    echo "El archivo fuente no existe: $SOURCE"
    exit 1
fi

sudo rm -f /etc/nginx/sites-enabled/default

# Reiniciar servicios
sudo systemctl restart nginx || {
    echo "Error al reiniciar Nginx, verifica si está instalado correctamente."
    exit 1
}
sudo systemctl restart php7.4-fpm || {
    echo "Error al reiniciar PHP-FPM, verifica si está instalado correctamente."
    exit 1
}
sudo systemctl enable nginx
sudo systemctl enable php7.4-fpm

# Comprobar que se conecta correctamente a la base de datos
USER=owncloud_user
IPDB=192.168.56.40
mysql -u "$USER" -p "$IPDB" -h  -e "SHOW DATABASES;"