#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

THIS_NAME="${1:?Kea server name is required}"
STATE_KA="${2:?Keepalived state is required}"
PRIO_KA="${3:?Keepalived priority is required}"
GW_WAN="172.26.0.1"
VIP_WAN="172.26.32.250"
VIP_LAN="192.168.10.1"
: "${DDNS_KEY:?DDNS_KEY must be supplied by Vagrant}"

apt-get update -y
apt-get install -y kea-dhcp4-server kea-dhcp-ddns-server kea-ctrl-agent keepalived nftables curl chrony python3 python3

IF_WAN=$(ip -o -4 addr show | awk '$4 ~ /^172\.26\.30\./ {print $2; exit}')
IF_LAN=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.10\./ {print $2; exit}')
if [ -z "$IF_WAN" ] || [ -z "$IF_LAN" ]; then
    echo "Could not detect the WAN and LAN interfaces." >&2
    exit 1
fi

export IF_WAN VIP_WAN VIP_LAN STATE_KA PRIO_KA THIS_NAME GW_WAN
RENDER=/vagrant/provision/render-template.py
CONFIG=/vagrant/config/kea

echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
sysctl --system

python3 "$RENDER" "$CONFIG/nftables.conf.tmpl" /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables

python3 "$RENDER" "$CONFIG/keepalived.conf.tmpl" /etc/keepalived/keepalived.conf
systemctl enable keepalived
systemctl restart keepalived

python3 "$RENDER" "$CONFIG/kea-dhcp-ddns.json.tmpl" /etc/kea/kea-dhcp-ddns.conf
systemctl enable kea-dhcp-ddns-server
systemctl restart kea-dhcp-ddns-server

python3 "$RENDER" "$CONFIG/kea-dhcp4.json.tmpl" /etc/kea/kea-dhcp4.conf
systemctl enable kea-dhcp4-server kea-ctrl-agent
systemctl restart kea-dhcp4-server kea-ctrl-agent

python3 "$RENDER" "$CONFIG/kea-fix-routes.sh.tmpl" /usr/local/sbin/kea-fix-routes.sh
chmod 750 /usr/local/sbin/kea-fix-routes.sh
install -m 0644 "$CONFIG/kea-routes.service" /etc/systemd/system/kea-routes.service
systemctl daemon-reload
systemctl enable kea-routes.service
/usr/local/sbin/kea-fix-routes.sh
