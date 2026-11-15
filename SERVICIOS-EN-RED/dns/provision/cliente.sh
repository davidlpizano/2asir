#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y bind9-dnsutils

cat > /etc/resolv.conf <<EOF
search asir.lan
nameserver 192.168.10.10
nameserver 192.168.10.11
EOF
