# 3-capas-basada-en-una-pila-LEMP
Este trabajo se trata de desplegar un CMS (OwnCloud o Jooma) en una infraestructura en alta disponibilidad de 3 capas basada en una pila LEMP.
# ÍNDICE
1. Introducción
2. Requisitos
3. Infraestructura
4. Aprovisionamiento de Máquinas Virtuales
5. Configuración de la Infraestructura
6. Configuración de OwnCloud
7. Verificación del Funcionamiento

## Introducción
En este proyecto, se ha desplegado una infraestructura de alta disponibilidad utilizando una arquitectura de tres capas basada en la pila LEMP (Linux, Nginx, MySQL/MariaDB, PHP). El objetivo es implementar el CMS OwnCloud en esta infraestructura, con balanceo de carga entre los servidores web y almacenamiento de archivos compartido a través de NFS.

### Direccionamiento IP
Balanceador de Carga (Capa 1): 192.168.56.10
Servidor Web 1 (Capa 2): 192.168.56.21
Servidor Web 2 (Capa 2): 192.168.56.22
Servidor NFS y PHP-FPM (Capa 2): 192.168.56.30
Servidor de Base de Datos MariaDB (Capa 3): 192.168.56.40
