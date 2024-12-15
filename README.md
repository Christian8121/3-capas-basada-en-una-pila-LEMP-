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


