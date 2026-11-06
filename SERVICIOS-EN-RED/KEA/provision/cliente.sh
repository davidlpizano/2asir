#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

hostnamectl set-hostname portatil-ana
apt-get update -y
apt-get install -y bind9-dnsutils isc-dhcp-client

IF_LAN=$(ip -o link show | awk -F': ' '$2 !~ /lo|eth0/ {print $2; exit}')
if [ -z "$IF_LAN" ]; then
    echo "Could not detect the client LAN interface." >&2
    exit 1
fi

dhclient -r "$IF_LAN" 2>/dev/null || true
dhclient -v -H "portatil-ana" "$IF_LAN"

IF_NAT=$(ip -o -4 addr show | awk '$4 ~ /^10\.0\.2\./ {print $2; exit}')
if [ -n "$IF_NAT" ]; then
    ip route del default dev "$IF_NAT" 2>/dev/null || true
fi
ip route replace default via 192.168.10.1 dev "$IF_LAN"
