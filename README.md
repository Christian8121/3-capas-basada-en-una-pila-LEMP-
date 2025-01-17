# Instalación de OwnCloud en Arquitectura de 3 Capas en Alta Disponibilidad

## Índice

1. [Introducción](#introducción)  
2. [Requisitos Previos](#requisitos-previos)  
3. [Infraestructura y Direccionamiento IP](#infraestructura-y-direccionamiento-ip)
4. [Estructura del Proyecto](#estructura-del-proyecto)  
5. [Vagrantfile](#vagrantfile) 
6. [Instalación y Configuración](#instalación-y-configuración)  
    - [Configuración del Balanceador de Carga](#configuración-del-balanceador-de-carga)  
    - [Configuración del Servidor de Base de Datos](#configuración-del-servidor-de-base-de-datos)  
    - [Configuración del Servidor NFS](#configuración-del-servidor-nfs)  
    - [Configuración de los Servidores Web](#configuración-de-los-servidores-web)
7. [Despliegue](#despliegue)  
8. [Conclusión](#conclusión)

---

## Introducción
En este proyecto se implementa un entorno virtualizado para la instalación y configuración de OwnCloud, un sistema de almacenamiento en la nube. La infraestructura se compone de múltiples máquinas virtuales gestionadas con Vagrant, asignando a cada máquina un rol específico: balanceador de carga, base de datos, servidor NFS y servidores web. El objetivo es garantizar alta disponibilidad mediante scripts de configuración automatizada.

---

## Requisitos Previos
- **Software necesario:**
  - Vagrant
  - VirtualBox
- **Recursos adicionales:**
  - Imagen base de Debian
  - Conexión a Internet para instalar paquetes

---

## Infraestructura y Direccionamiento IP
### Red y Rol de las Máquinas

1. **Balanceador de carga:** Gestiona el tráfico entre los servidores web.  
   - **IP:** 192.168.56.2  
   - **Acceso:** Público y privado

2. **Servidores web:** Ejecutan OwnCloud y acceden al almacenamiento compartido.  
   - **Web1-IP:** 192.168.56.10 y 192.168.60.11
   - **Web2-IP:** 192.168.56.11 y 192.168.60.12
3. **Servidor NFS:** Proporciona almacenamiento compartido a los servidores web.  
   - **IP:** 192.168.56.12 y 192.168.60.13

4. **Servidor de base de datos:** Gestiona la base de datos de OwnCloud con MariaDB.  
   - **IP:** 192.168.60.10

### Redes Virtuales
- **red_balancer_red:** Conecta el balanceador con los servidores web y NFS.
- **red_sgbd_webs_nfs:** Conecta los servidores web, NFS y el servidor de base de datos.

---

## Estructura del Proyecto
```
├── balancer.sh          # Script para el balanceador de carga
├── nfs.sh               # Script para el servidor NFS
├── web.sh               # Script para los servidores web
├── db.sh                # Script para la base de datos
├── Vagrantfile          # Configuración de las máquinas virtuales
└── README.md            # Documentación del proyecto
```

---

## Vagrantfile
El archivo Vagrantfile define las máquinas virtuales y su configuración. Puedes encontrarlo en el directorio raíz del proyecto.
- **Provisión:** Configuración automática mediante scripts.

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
config.vm.box = "debian/bullseye64"
 config.vm.define "BalancerSeve" do |app|
    app.vm.hostname = "BalancerSeve"
    app.vm.network "public_network" 
    app.vm.network "private_network", ip: "192.168.56.2", virtualbox_intnet: "red_balancer_webs"
    app.vm.provision "shell", path: "balanceador.sh"

 config.vm.define "NFSSeve" do |app|
    app.vm.hostname = "NFSSeve"
    app.vm.network "private_network", ip: "192.168.60.13", virtualbox_intnet: "red_sgbd_webs_nfs"
    app.vm.network "private_network", ip: "192.168.56.12", virtualbox_intnet: "red_balancer_webs"
    app.vm.provision "shell", path: "nfs.sh"
  end

config.vm.define "SGBDDSeve" do |app|
    app.vm.hostname = "SGBDDSeve"
    app.vm.network "private_network", ip: "192.168.60.10", virtualbox_intnet: "red_sgbd_webs_nfs"
    app.vm.provision "shell", path: "basedatos.sh"
  end

  config.vm.define "Web1Seve" do |app|
    app.vm.hostname = "Web1Seve"
    app.vm.network "private_network", ip: "192.168.60.11", virtualbox_intnet: "red_sgbd_webs_nfs"
    app.vm.network "private_network", ip: "192.168.56.10", virtualbox_intnet: "red_balancer_webs"
    app.vm.provision "shell", path: "web.sh"
    # Mapeo de puertos: Acceder a Owncloud desde Windows a través del puerto 8080
    app.vm.network "forwarded_port", guest: 80, host: 8080
  end

  config.vm.define "Web2Seve" do |app|
    app.vm.hostname = "Web2Seve"
    app.vm.network "private_network", ip: "192.168.60.12", virtualbox_intnet: "red_sgbd_webs_nfs"
    app.vm.network "private_network", ip: "192.168.56.11", virtualbox_intnet: "red_balancer_webs"
    app.vm.provision "shell", path: "web.sh"
    # Mapeo de puertos: Acceder a Owncloud desde Windows a través del puerto 8080
    app.vm.network "forwarded_port", guest: 80, host: 8080
  end
end 
```

### Máquinas Definidas

1. **Balanceador:** IP pública y privada, configura Nginx para balanceo de carga.
El balanceador distribuye las solicitudes entre los servidores web. El archivo provision_balanceador.sh configura Nginx para balancear la carga:

2. **Servidores web:** Conectados al balanceador y al almacenamiento NFS.
Los servidores web configuran Nginx para servir el contenido de OwnCloud desde el directorio compartido por NFS:

3. **Servidor NFS:** Proporciona almacenamiento compartido para los servidores web.
El servidor NFS permite compartir el directorio de datos entre los servidores web, mientras que PHP-FPM es necesario para ejecutar el CMS:

4. **Base de datos:** Servidor MariaDB con acceso limitado por subred.
MariaDB se configura en el servidor de base de datos para crear la base de datos y los usuarios necesarios:

---

## Instalación y Configuración

### Configuración del Balanceador de Carga

```bash
#!/bin/bash

# Actualizar repositorios e instalar nginx
sudo apt-get update -y
sudo apt-get install -y nginx

# Configuracion de Nginx como balanceador de carga
cat <<EOF > /etc/nginx/sites-available/default
upstream backend_servers {
    server 192.168.56.10;
    server 192.168.56.11;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

EOF

# Reiniciar nginx para aplicar cambios
sudo systemctl restart nginx
   ```

### Configuración del Servidor de Base de Datos

```bash
#!/bin/bash

# Actualizar repositorios e instalar MariaDB
sudo apt-get update -y
sudo apt-get install -y mariadb-server

# Configurar MariaDB para permitir acceso remoto desde los servidores web
sed -i 's/bind-address.*/bind-address = 192.168.60.10/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Reiniciar MariaDB
sudo systemctl restart mariadb

# Crear base de datos y usuario para OwnCloud
mysql -u root <<EOF
CREATE DATABASE owncloud;
CREATE USER 'owncloud'@'192.168.60.%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'192.168.60.%';
FLUSH PRIVILEGES;
EOF

#Eliminar puerta de enlace por defecto de Vagrant
sudo ip route del default 

```

### Configuración del Servidor NFS
Instala el servidor NFS y paquetes necesarios para OwnCloud.

```bash
  #!/bin/bash

# Actualizar repositorios e instalar NFS y PHP 7.4
sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap unzip

# Crear carpeta compartida para OwnCloud y configurar permisos
sudo mkdir -p /var/www/html
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Configurar NFS para compartir la carpeta
echo "/var/www/html 192.168.10.5(rw,sync,no_subtree_check)" >> /etc/exports
echo "/var/www/html 192.168.10.6(rw,sync,no_subtree_check)" >> /etc/exports

# Reiniciar NFS para aplicar cambios
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Descargar y configurar OwnCloud
cd /tmp
wget https://download.owncloud.com/server/stable/owncloud-10.9.1.zip
unzip owncloud-10.9.1.zip
mv owncloud /var/www/html/

# Configurar permisos de OwnCloud
sudo chown -R www-data:www-data /var/www/html/owncloud
sudo chmod -R 755 /var/www/html/owncloud

# Crear archivo de configuración inicial para OwnCloud
cat <<EOF > /var/www/html/owncloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype" => "mysql",
  "dbname" => "owncloud",
  "dbuser" => "owncloud",
  "dbpassword" => "12345",
  "dbhost" => "192.168.30.10",
  "directory" => "/var/www/html/owncloud/data",
  "adminlogin" => "severino",
  "adminpass" => "1234?"
);
EOF

# Modificar el archivo config.php para agregar los dominios de confianza
echo "Añadiendo dominios de confianza a la configuración de OwnCloud..."
php -r "
  \$configFile = '/var/www/html/owncloud/config/config.php';
  if (file_exists(\$configFile)) {
    \$config = include(\$configFile);
    \$config['trusted_domains'] = array(
      'localhost',
      'localhost:8080',
      '192.168.10.5',
      '192.168.10.6',
      '192.168.10.12',
    );
    file_put_contents(\$configFile, '<?php return ' . var_export(\$config, true) . ';');
  } else {
    echo 'No se pudo encontrar el archivo config.php';
  }
"

# Configuración de PHP-FPM para escuchar en la IP del servidor NFS
sed -i 's/^listen = .*/listen = 192.168.10.12:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Reiniciar PHP-FPM
sudo systemctl restart php7.4-fpm

#Eliminar puerta de enlace por defecto de Vagrant
sudo ip route del default
```

### Configuración del Servidores Web

```bash
#!/bin/bash

# Actualizar repositorios e instalar nginx, nfs-common, PHP 7.4 y cliente mariadb
sudo apt-get update -y
sudo apt-get install -y nginx nfs-common php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap mariadb-client

# Crear la carpeta compartida por NFS
sudo mkdir -p /var/www/html

# Montar la carpeta desde el servidor NFS
sudo mount -t nfs 192.168.56.12:/var/www/html /var/www/html

# Añadir entrada al /etc/fstab para montaje automático
echo "192.168.56.12:/var/www/html /var/www/html nfs defaults 0 0" >> /etc/fstab

# Configuración de Nginx para servir OwnCloud
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;

    root /var/www/html/owncloud;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass 192.168.56.12:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ ^/(?:\.htaccess|data|config|db_structure\.xml|README) {
        deny all;
    }
}
EOF

# Verificar la configuración de Nginx
nginx -t

# Reiniciar Nginx para aplicar los cambios
sudo systemctl restart nginx

# Reiniciar PHP-FPM 7.4
sudo systemctl restart php7.4-fpm

# Eliminar puerta de enlace por defecto de Vagrant
sudo ip route del default
---

## Despliegue
1. Ejecuta Vagrant para levantar las máquinas.
   ```bash
   vagrant up
 ```
## Despliegue
1. Ejecuta Vagrant para levantar las máquinas.
   ```bash
   vagrant up
   ```
2. Accede al balanceador y verifica el funcionamiento de OwnCloud desde un navegador.
1. Abre tu navegador web (por ejemplo, Chrome, Firefox, Edge).
2. Ingresa la dirección IP del balanceador de carga en la barra de direcciones:
```
http://Direción-ip
```
![Captura de pantalla 2025-01-15 112808](https://github.com/user-attachments/assets/3fe70bea-1c6d-44b3-85ce-cfcc1a8bfc60)
![image](https://github.com/user-attachments/assets/32ca9362-ce15-4f05-80dd-d36422b1a417)
![image](https://github.com/user-attachments/assets/d604bce1-eeaf-49e4-9007-122ca5d6696d)
![image](https://github.com/user-attachments/assets/b11ee53d-97dc-486b-ab1e-c8039bf82c31)
![image](https://github.com/user-attachments/assets/e46eef1f-2cfc-4088-b500-cd48b6dd4925)

---

## Conclusión
El proyecto demuestra cómo implementar una arquitectura de tres capas con alta disponibilidad para OwnCloud utilizando Vagrant. Cada componente se configura para garantizar escalabilidad, estabilidad y una experiencia optimizada de almacenamiento en la nube.
