#!/bin/bash
set -e

# ======================================
# 00 - HAProxy VIP pour Kubernetes multi-controlplane
# ======================================

CONTROLPLANE_VIP="${CONTROLPLANE_VIP:-192.168.1.210}"
NUM_CONTROLPLANE="${NUM_CONTROLPLANE:-1}"
IP_START="${IP_START:-192.168.1.200}"

export DEBIAN_FRONTEND=noninteractive

echo "🛠️  Installing HAProxy with VIP $CONTROLPLANE_VIP"
apt-get update -y >/dev/null
apt-get install -y haproxy

# Génération des IP des controlplanes
BASE_IP=$(echo "$IP_START" | cut -d. -f1-3)   # 192.168.1
START_OCTET=$(echo "$IP_START" | cut -d. -f4) # 230

echo "⚙️  Generating HAProxy configuration for VIP $CONTROLPLANE_VIP"
cat <<EOF > /etc/haproxy/haproxy.cfg
global
  log /dev/log local0
  maxconn 2048
  user haproxy
  group haproxy
  daemon

defaults
  log     global
  mode    tcp
  option  tcplog
  timeout connect 10s
  timeout client  1m
  timeout server  1m

frontend kubernetes-frontend-api
  bind ${CONTROLPLANE_VIP}:6443
  default_backend kubernetes-backend-api

backend kubernetes-backend-api
  balance roundrobin
  option tcp-check
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
EOF

# default-server inter 3s fall 3 rise 2
# Adding controlplanes as server in the backend
for i in $(seq 0 $((NUM_CONTROLPLANE - 1))); do
  IP="${BASE_IP}.$((START_OCTET + i))"
  echo "  server controlplane0$((i + 1)) ${IP}:6443 check" >> /etc/haproxy/haproxy.cfg
done

echo "📘 Generated file /etc/haproxy/haproxy.cfg :"
echo "-------------------------------------"
cat /etc/haproxy/haproxy.cfg
echo "-------------------------------------"
echo "ℹ️  Restarting HAProxy with new configuration ..."
systemctl restart haproxy
systemctl enable haproxy


# Add haproxy-vip in /vagrant/hosts
echo "$CONTROLPLANE_VIP $CLUSTER_NAME-haproxy-vip" >> /vagrant/hosts


# # Generated SSH keys for user vagrant
# ssh-keygen -t rsa -b 2048 -N "" -f /home/vagrant/.ssh/id_rsa
# chown vagrant:vagrant /home/vagrant/.ssh/id_rsa
# chmod 600 /home/vagrant/.ssh/id_rsa
# cp /home/vagrant/.ssh/id_rsa.pub /vagrant/id_rsa.vagrant.$(hostname).pub

echo "🏁 HAProxy is ready with VIP ${CONTROLPLANE_VIP}:6443"
