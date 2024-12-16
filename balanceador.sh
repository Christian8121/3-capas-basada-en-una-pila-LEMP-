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
