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

