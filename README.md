# Project-Kubernetes-Promox

A repo of a project to deploy Kubernetes on Proxmox

- Specification:
  - Control node:
    - OS: Ubuntu
    - CPU: 1 cores
    - Memory: 2048
  - Worker node:
    - OS: Ubuntu
    - CPU: 4 cores
    - Memory: 4096





```sh
# backup
cd /etc/netplan/

sudo cp 50-cloud-init.yaml 50-cloud-init.yaml.bak
# set ip

sudo tee 50-cloud-init.yaml<<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.100.150/24
      routes:
        - to: default
          via: 192.168.100.254
      nameservers:
        addresses: [192.168.100.254, 8.8.8.8, 1.1.1.1]
EOF

sudo netplan apply

# install containerd
sudo apt update
sudo apt-get -y install podman
podman version

sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb

minikube version
minikube start --driver=podman 
minikube config set driver podman

```