#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
: "${TRANSFER_KEY:?TRANSFER_KEY must be supplied by Vagrant}"

apt-get update -y
apt-get install -y bind9 bind9-utils bind9-dnsutils chrony curl python3

install -d -o root -g bind -m 0750 /etc/bind/keys
cat > /etc/bind/keys/transfer.key <<EOF
key "transfer-key" {
    algorithm hmac-sha256;
    secret "$TRANSFER_KEY";
};
EOF
chown root:bind /etc/bind/keys/transfer.key
chmod 0640 /etc/bind/keys/transfer.key

export DNS_IP="192.168.10.10"
RENDER=/vagrant/provision/render-template.py
CONFIG=/vagrant/config
python3 "$RENDER" "$CONFIG/named.conf.options.tmpl" /etc/bind/named.conf.options
install -m 0640 "$CONFIG/named.conf.local.dns1.example" /etc/bind/named.conf.local
install -o bind -g bind -m 0640 "$CONFIG/zones/db.asir.lan" /var/lib/bind/db.asir.lan
install -o bind -g bind -m 0640 "$CONFIG/zones/db.10.168.192" /var/lib/bind/db.10.168.192

named-checkconf
named-checkzone asir.lan /var/lib/bind/db.asir.lan
named-checkzone 10.168.192.in-addr.arpa /var/lib/bind/db.10.168.192
systemctl enable bind9 chrony
systemctl restart bind9 chrony

echo "nameserver 127.0.0.1" > /etc/resolv.conf
