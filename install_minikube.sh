#!/bin/bash

echo
echo "# ##############################"
echo "# set hostname"
echo "# ##############################"
echo
sudo hostnamectl set-hostname minikube

# add hosts
sudo tee -a /etc/hosts <<EOF
192.168.100.150   minikube
127.0.0.1        localhost
EOF

echo
echo "# ########################################"
echo "# Netplan Static IP Configuration"
echo "# ########################################"
echo 

sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 192.168.10.150/24
      routes:
        - to: default
          via: 192.168.100.254
      nameservers:
        addresses: [192.168.100.254, 8.8.8.8, 1.1.1.1]
EOF

sudo chmod 600 /etc/netplan/*
sudo netplan apply

# confirm
ip a
ping -c 3 google.com

echo
echo "# ########################################"
echo "# Update Packages + Install Basic Tools"
echo "# ########################################"
echo 

sudo apt update && sudo apt upgrade -y
sudo apt install -y vim git curl ca-certificates net-tools traceroute tcpdump htop

echo
echo "# ##############################"
echo "# Disable Swap"
echo "# ##############################"
echo 

sudo swapoff -a
sudo sed -i '/swap/ s/^/#/' /etc/fstab

# confirm
free -h

echo 
echo "# ##############################"
echo "# Disable Swap"
echo "# ##############################"
echo 
# uninstall all conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove $pkg;
done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker Engine.
sudo systemctl enable --now docker
# Verify
sudo docker run hello-world

echo 
echo "# ##############################"
echo "# Install kubectl"
echo "# ##############################"
echo 

# Download the latest release
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# verify
kubectl version --client

echo 
echo "# ##############################"
echo "# Install minikube"
echo "# ##############################"
echo 
# install the latest minikube stable release on x86-64 Linux using Debian package
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb

# use unprivilege user, due to minikube cannot start as root.
su - ubuntuadmin
sudo usermod -aG docker $USER && newgrp docker

# confirm
minikube version

echo 
echo "# ##############################"
echo "# Start minikube"
echo "# ##############################"
echo 
minikube start --driver=docker

echo 
echo "# ##############################"
echo "# Set minikube as service"
echo "# ##############################"
echo 

# Set minikube as service
sudo tee /etc/systemd/system/minikube.service <<EOF
[Unit]
Description=Minikube Kubernetes Cluster
After=docker.service

[Service]
ExecStart=/usr/bin/minikube start --driver=docker
ExecStop=/usr/bin/minikube stop
Restart=on-failure
User=${USER}
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# reload config
sudo systemctl daemon-reload
# enable
sudo systemctl enable --now minikube