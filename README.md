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
   - **IP:** 192.168.56.10 y 192.168.56.11

3. **Servidor NFS:** Proporciona almacenamiento compartido a los servidores web.  
   - **IP:** 192.168.56.12

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
### Descripción General

- **`config.vm.box`:** Define la imagen base (Debian Bullseye).
- **`config.vm.define`:** Define las máquinas virtuales y sus roles.
- **Redes:** Redes privadas y públicas para la conexión entre máquinas.
- **Provisión:** Configuración automática mediante scripts.

### Máquinas Definidas

1. **Balanceador:** IP pública y privada, configura Nginx para balanceo de carga.
2. **Servidores web:** Conectados al balanceador y al almacenamiento NFS.
3. **Servidor NFS:** Proporciona almacenamiento compartido para los servidores web.
4. **Base de datos:** Servidor MariaDB con acceso limitado por subred.

---

## Instalación y Configuración

### Configuración del Balanceador de Carga
1. Actualiza e instala Nginx.
   ```bash
   sudo apt-get update -y
   sudo apt-get install -y nginx
   ```
2. Configura Nginx para balanceo de carga.
   ```bash
   cat <<EOF > /etc/nginx/sites-available/default
   upstream backend_servers {
       server 192.168.56.10;
       server 192.168.56.11;
   }

   server {
       listen 80;
       location / {
           proxy_pass http://backend_servers;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       }
   }
   EOF
   sudo systemctl restart nginx
   ```

### Configuración del Servidor de Base de Datos
1. Instala MariaDB y configura la IP de escucha.
   ```bash
   sudo apt-get install -y mariadb-server
   sed -i 's/bind-address.*/bind-address = 192.168.60.10/' /etc/mysql/mariadb.conf.d/50-server.cnf
   sudo systemctl restart mariadb
   ```
2. Crea la base de datos y el usuario para OwnCloud.
   ```bash
   mysql -u root <<EOF
   CREATE DATABASE owncloud;
   CREATE USER 'owncloud'@'192.168.60.%' IDENTIFIED BY '1234';
   GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'192.168.60.%';
   FLUSH PRIVILEGES;
   EOF
   ```

### Configuración del Servidor NFS
1. Instala el servidor NFS y paquetes necesarios para OwnCloud.
   ```bash
   sudo apt-get install -y nfs-kernel-server php7.4 php7.4-fpm ...
   ```
2. Configura el almacenamiento compartido.
   ```bash
   sudo mkdir -p /var/www/html
   sudo chown -R www-data:www-data /var/www/html
   sudo chmod -R 755 /var/www/html
   echo "/var/www/html 192.168.56.10(rw,sync,no_subtree_check)" >> /etc/exports
   sudo exportfs -a
   sudo systemctl restart nfs-kernel-server
   ```

3. Descarga y configura OwnCloud.
   ```bash
   wget https://download.owncloud.com/server/stable/owncloud-10.9.1.zip
   unzip owncloud-10.9.1.zip
   mv owncloud /var/www/html/
   sudo chown -R www-data:www-data /var/www/html/owncloud
   sudo chmod -R 755 /var/www/html/owncloud
   ```

4. Crea el archivo de configuración inicial de OwnCloud.
   ```bash
   cat <<EOF > /var/www/html/owncloud/config/autoconfig.php
   <?php
   $AUTOCONFIG = array(
       "dbtype" => "mysql",
       "dbname" => "owncloud",
       "dbuser" => "owncloud",
       "dbpassword" => "1234",
       "dbhost" => "192.168.60.10",
       "directory" => "/var/www/html/owncloud/data",
       "adminlogin" => "admin",
       "adminpass" => "password"
   );
   EOF
   ```

---

## Despliegue
1. Ejecuta Vagrant para levantar las máquinas.
   ```bash
   vagrant up
   ```
2. Accede al balanceador y verifica el funcionamiento de OwnCloud desde un navegador.

---

## Conclusión
El proyecto demuestra cómo implementar una arquitectura de tres capas con alta disponibilidad para OwnCloud utilizando Vagrant. Cada componente se configura para garantizar escalabilidad, estabilidad y una experiencia optimizada de almacenamiento en la nube.
