#!/bin/bash

check_command_success() {
  if [ $? -eq 0 ]; then
    echo "done"
  else
    exit 1
  fi
}

EASYRSA_DIR="$HOME/openvpn-ca"
SERVER_IP="18.141.176.250"

cd $EASYRSA_DIR

check_command_success

CERT_FILE="$EASYRSA_DIR/pki/issued/$1.crt"
KEY_FILE="$EASYRSA_DIR/pki/private/$1.key"

if [ -f "$CERT_FILE" -a -f "$KEY_FILE" ]; then
    echo "Cert & Key Files are already exists. Just Generating ovpn file!...."
else
    ./easyrsa gen-req $1 nopass
    ./easyrsa sign-req client $1
fi


CA_CONTENT=$(cat $EASYRSA_DIR/pki/ca.crt)
CERT_CONTENT=$(cat $CERT_FILE)
KEY_CONTENT=$(cat $KEY_FILE)

echo "Generating ovpn file for $1...."

cat <<EOF > $HOME/$1.ovpn
client
dev tun
proto udp
remote $SERVER_IP 1220
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-256-CBC
verb 3

<ca>
$CA_CONTENT
</ca>

<cert>
$CERT_CONTENT
</cert>

<key>
$KEY_CONTENT
</key>
EOF

check_command_success

echo "Succeeded generating ovpn file!...."