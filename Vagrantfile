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
