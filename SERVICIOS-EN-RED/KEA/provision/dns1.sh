#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
: "${TRANSFER_KEY:?TRANSFER_KEY must be supplied by Vagrant}"
: "${DDNS_KEY:?DDNS_KEY must be supplied by Vagrant}"

apt-get update -y
apt-get install -y bind9 bind9-utils bind9-dnsutils chrony curl python3

install -d -o root -g bind -m 0750 /etc/bind/keys
cat > /etc/bind/keys/transfer.key <<EOF
key "transfer-key" {
    algorithm hmac-sha256;
    secret "$TRANSFER_KEY";
};
EOF
cat > /etc/bind/keys/ddns.key <<EOF
key "ddns-key" {
    algorithm hmac-sha256;
    secret "$DDNS_KEY";
};
EOF
chown root:bind /etc/bind/keys/*.key
chmod 0640 /etc/bind/keys/*.key

export DNS_IP="192.168.10.10"
RENDER=/vagrant/provision/render-template.py
CONFIG=/vagrant/config/bind
python3 "$RENDER" "$CONFIG/named.conf.options.tmpl" /etc/bind/named.conf.options
install -m 0640 "$CONFIG/named.conf.local.dns1.example" /etc/bind/named.conf.local
install -o bind -g bind -m 0640 "$CONFIG/zones/db.asir.lan" /var/lib/bind/db.asir.lan
install -o bind -g bind -m 0640 "$CONFIG/zones/db.10.168.192" /var/lib/bind/db.10.168.192

named-checkconf
named-checkzone asir.lan /var/lib/bind/db.asir.lan
named-checkzone 10.168.192.in-addr.arpa /var/lib/bind/db.10.168.192
systemctl enable bind9 chrony
systemctl restart bind9 chrony

IF_LAN=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.10\./ {print $2; exit}')
IF_NAT=$(ip -o -4 addr show | awk '$4 ~ /^10\.0\.2\./ {print $2; exit}')
if [ -z "$IF_LAN" ]; then
    echo "Could not detect the DNS LAN interface." >&2
    exit 1
fi
if [ -n "$IF_NAT" ]; then
    ip route del default dev "$IF_NAT" 2>/dev/null || true
fi
ip route replace default via 192.168.10.1 dev "$IF_LAN"
echo "nameserver 127.0.0.1" > /etc/resolv.conf
