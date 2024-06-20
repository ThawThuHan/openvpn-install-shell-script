#!/bin/bash

# check_root() {
#   if [ "$EUID" -ne 0 ]; then
#     echo "This script must be run as root."
#     exit 1
#   fi
# }

# check_root

check_command_success() {
  if [ $? -eq 0 ]; then
    echo "done"
  else
    exit 1
  fi
}

echo "
Installing OpenVPN and EasyRSA
==============================
"

OS=$(cat /etc/os-release | grep ID_LIKE | sed 's/ID_LIKE=//g' | tr -d '"')

if [[ $OS == *"debian"* ]]
then
  echo "debian base OS, install OpenVpn and EasyRSA by using apt...."
  sudo apt update && sudo apt upgrade -y
  sudo apt install openvpn easy-rsa -y
elif [[ $OS == *"rhel"* ]] 
then
  echo "rhel base OS, install OpenVpn and EasyRSA by using yum...."
  sudo yum update -y
  sudo yum install epel-release -y
  sudo yum install openvpn easy-rsa -y
fi

echo "
configure OS network setting for Openvpn
========================================"

CHECK_IP_FORWARD_EXIST=$(sysctl -p /etc/sysctl.conf)

if [[ $CHECK_IP_FORWARD_EXIST == "net.ipv4.ip_forward = 1" ]]
then
  echo "ip forward setting is already exist...."
else
  # echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
fi

sudo sysctl -p /etc/sysctl.conf

NET_IF_NAME=$(ip -o addr show up primary scope global | awk '{print $2}' | head -n 1) 

sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $NET_IF_NAME -j MASQUERADE \
&& echo "NAT setting added...." || echo "NAT setting add failed!...."

echo "
configure TLS/SSL certificate for Openvpn
========================================="

if [[ $OS == *"debian"* ]]
then
  make-cadir ~/openvpn-ca
  cd ~/openvpn-ca
elif [[ $OS == *"rhel"* ]] 
then
  mkdir ~/openvpn-ca
  cd ~/openvpn-ca
  EASYRSA_DIR=$(find /usr/share/easy-rsa/ -type f -name easyrsa -exec dirname {} \;)
  cp -r $EASYRSA_DIR/* .
fi

echo "
Build CA certificate for Openvpn
--------------------------------"

./easyrsa init-pki
./easyrsa build-ca

check_command_success

echo "
Build Server certificate for OpenVPN
------------------------------------"

./easyrsa gen-req openvpn-server nopass
./easyrsa sign-req server openvpn-server

echo "
generate diffie-hellman
-----------------------"
./easyrsa gen-dh

echo "
copying the ca, server and key files to the openvpn config (/etc/openvpn)..."

if [[ $OS == *"debian"* ]]
then
  sudo cp pki/ca.crt pki/dh.pem pki/issued/openvpn-server.crt pki/private/openvpn-server.key /etc/openvpn/
elif [[ $OS == *"rhel"* ]] 
then
  sudo cp pki/ca.crt pki/dh.pem pki/issued/openvpn-server.crt pki/private/openvpn-server.key /etc/openvpn/server/
fi

check_command_success

echo "
Creating server.conf file in the /etc/openvpn...."

create_server_conf() {
cat << EOF | sudo tee -a $1
port 1220
proto udp
dev tun
ca ca.crt
cert openvpn-server.crt
key openvpn-server.key
dh dh.pem
server 10.8.0.0 255.255.255.0
keepalive 10 120
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
cipher AES-256-CBC
persist-key
persist-tun
explicit-exit-notify 1
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
verb 4
EOF
}

if [[ $OS == *"debian"* ]]
then
  create_server_conf /etc/openvpn/server.conf
elif [[ $OS == *"rhel"* ]] 
then
  create_server_conf /etc/openvpn/server/server.conf
fi

check_command_success

echo "
Starting the openvpn service...."

if [[ $OS == *"debian"* ]]
then
  sudo systemctl start openvpn@server
  sudo systemctl enable openvpn@server
elif [[ $OS == *"rhel"* ]] 
then
  sudo systemctl start openvpn-server@server
  sudo systemctl enable openvpn-server@server
fi

check_command_success