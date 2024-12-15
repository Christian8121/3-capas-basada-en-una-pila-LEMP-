# 3-capas-basada-en-una-pila-LEMP
Este trabajo se trata de desplegar un CMS (OwnCloud o Jooma) en una infraestructura en alta disponibilidad de 3 capas basada en una pila LEMP.
# ÍNDICE
1. Introducción
2. Infraestructura
3. Aprovisionamiento de Máquinas Virtuales
4. Configuración de la Infraestructura
5. Configuración de OwnCloud
6. Verificación del Funcionamiento

## 1. Introducción
En este proyecto, se ha desplegado una infraestructura de alta disponibilidad utilizando una arquitectura de tres capas basada en la pila LEMP (Linux, Nginx, MySQL/MariaDB, PHP). El objetivo es implementar el CMS OwnCloud en esta infraestructura, con balanceo de carga entre los servidores web y almacenamiento de archivos compartido a través de NFS.

### Direccionamiento IP
* Balanceador de Carga (Capa 1): 192.168.56.10
* Servidor Web 1 (Capa 2): 192.168.56.21
* Servidor Web 2 (Capa 2): 192.168.56.22
* Servidor NFS y PHP-FPM (Capa 2): 192.168.56.30
* Servidor de Base de Datos MariaDB (Capa 3): 192.168.56.40

## 2. Infraestructura
La infraestructura está compuesta por tres capas:

* Capa 1 - Balanceador de Carga (Nginx): El balanceador de carga se encarga de distribuir las solicitudes entrantes entre los dos servidores web.

* Capa 2 - Backend:
Servidor Web 1 y 2 (Nginx): Estos servidores gestionan las solicitudes HTTP y sirven el contenido de OwnCloud.
Servidor NFS y PHP-FPM: Este servidor proporciona el sistema de archivos compartido (NFS) y el motor PHP-FPM necesario para ejecutar OwnCloud.

* Capa 3 - Base de Datos:
Servidor MariaDB: Gestiona la base de datos de OwnCloud.

![Diagrama en blanco (2)](https://github.com/user-attachments/assets/eb3a9431-b25a-439f-ad4d-02f9251e8db6)

## 3. Aprovisionamiento de Máquinas Virtuales
### Vagrantfile
El archivo Vagrantfile define las máquinas virtuales y su configuración. Puedes encontrarlo en el directorio raíz del proyecto.

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Box base
  config.vm.box = "debian/bullseye64"

  # Configuración del servidor NFS
  config.vm.define "serverNFSSeverino" do |nfs|
    nfs.vm.hostname = "serverNFSSeverino"
    nfs.vm.network "private_network", ip: "192.168.56.30"
    nfs.vm.provider "virtualbox" do |vb|
      vb.name = "serverNFSSeverino"
      vb.memory = 512
      vb.cpus = 1
    end
    nfs.vm.provision "shell", path: "nfsserver.sh"
  end

  # Configuración del servidor de base de datos
  config.vm.define "serverDBSeverino" do |db|
    db.vm.hostname = "serverDBSeverino"
    db.vm.network "private_network", ip: "192.168.56.40"
    db.vm.provider "virtualbox" do |vb|
      vb.name = "serverDBSeverino"
      vb.memory = 512
      vb.cpus = 1
    end
    db.vm.provision "shell", path: "dbserver.sh"
  end

  # Configuración de las máquinas backend
  ["serverweb1Severino", "serverweb2Severino"].each_with_index do |name, index|
    config.vm.define name do |server|
      server.vm.hostname = name
      server.vm.network "private_network", ip: "192.168.56.2#{index + 1}"
      server.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.memory = 512
        vb.cpus = 1
      end
      server.vm.provision "shell", path: "webserver.sh"
    end
  end

  # Configuración de la máquina balanceadora
  config.vm.define "balanceadorSeverino" do |balanceador|
    balanceador.vm.hostname = "balanceadorSeverino"
    balanceador.vm.network "public_network"
    balanceador.vm.network "private_network", ip: "192.168.56.10"
    balanceador.vm.provider "virtualbox" do |vb|
      vb.name = "balanceadorSeverino"
      vb.memory = 512
      vb.cpus = 1
    end
    balanceador.vm.provision "shell", path: "balanceador.sh"
  end

end

```

## 4. Configuración de la Infraestructura
A continuación, se detallan los scripts de aprovisionamiento para cada máquina virtual.

### 1. Balanceador de Carga (Nginx)
El balanceador distribuye las solicitudes entre los servidores web. El archivo provision_balanceador.sh configura Nginx para balancear la carga:

```
#!/bin/bash

# Actualizar el sistema
sudo apt update -y && sudo apt upgrade -y

# Instalar Nginx
sudo apt install -y nginx

# Configuración básica de Nginx como balanceador de carga
cat > /etc/nginx/sites-available/owncloud << EOF
upstream servidoresweb {
    server 192.168.56.21;
    server 192.168.56.22;
}

server {
   listen      80;
   server_name balanceadorSeverino;

   location / {
       proxy_redirect      off;
       proxy_set_header    X-Real-IP \$remote_addr;
       proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
       proxy_set_header    Host \$http_host;
       proxy_pass          http://servidoresweb;
   }
}
EOF

# Activar la configuración
sudo ln -s /etc/nginx/sites-available/owncloud /etc/nginx/sites-enabled/

# Instalar UFW si no está instalado
if ! command -v ufw &> /dev/null; then
    sudo apt install -y ufw
fi

# Configuración inicial del firewall: Permitir SSH
sudo ufw allow ssh

# Establecer políticas predeterminadas para denegar todas las conexiones entrantes y permitir las salientes
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir el puerto 80 con persistencia
sudo ufw allow 80/tcp

# Habilitar el firewall
sudo ufw --force enable

# Reiniciar Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

![image](https://github.com/user-attachments/assets/c0e61c30-19a1-4406-b313-6a136f68d9fa)

### El estado de Nginx
![image](https://github.com/user-attachments/assets/aade548b-c3ed-4c92-a06e-ce619ca2c19e)
![image](https://github.com/user-attachments/assets/03f17e2a-bd10-46d3-bd26-879a52230a57)

### 2. Servidores Web (Nginx)
Los servidores web configuran Nginx para servir el contenido de OwnCloud desde el directorio compartido por NFS:

```
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
sudo apt-get install mariadb-client -y
USER=owncloud_user
IPDB=192.168.56.40
mysql -u "$USER" -p -h "$IPDB"  -e "SHOW DATABASES;"
```

![image](https://github.com/user-attachments/assets/8f84f812-f9fc-4df4-a5f0-097b283528d7)

### Mostrando el sistema de archivos montado en el servidor web 1 y 2
* Server 1

![image](https://github.com/user-attachments/assets/78355f7c-88c8-4b6a-89d9-9bccd50b0400)

* Server 2
  
![image](https://github.com/user-attachments/assets/fb565ede-7832-49f5-af45-859b355de184)

