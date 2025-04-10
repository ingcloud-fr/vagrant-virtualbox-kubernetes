#!/usr/bin/env bash
# ================================
# Met à jour /etc/hosts + crée public-ip
# ================================

set -e

IP_NW=$1
BUILD_MODE=$2
NUM_WORKER_NODES=$3
MASTER_IP_START=$4
NODE_IP_START=$5

# Fonction pour créer la commande public-ip
create_public_ip() {
  local ip="$1"
  cat <<EOF > /usr/local/bin/public-ip
#!/usr/bin/env sh
echo -n $ip
EOF
  chmod +x /usr/local/bin/public-ip
}

# Pour mod BRIDGE_STATIC et BRIDGE_DYN
if [[ "$BUILD_MODE" =~ ^BRIDGE ]]; then

  echo "[DEBUG] Interfaces réseau disponibles dans la VM :"
  ip a
  echo "[DEBUG] Table de routage :"
  ip route

  # Priorité à enp0s8 (interface bridge VirtualBox)
  if ip a show enp0s8 &>/dev/null; then
    BRIDGE_IFACE="enp0s8"
  else
    BRIDGE_IFACE=$(ip route | grep default | grep -Ev '10\.' | awk '{ print $5 }' | head -n1)
    if [ -z "$BRIDGE_IFACE" ]; then
      echo "[ERREUR] Impossible de détecter une interface bridge."
      exit 1
    fi
  fi

  for i in {1..30}; do
    MY_IP=$(ip -o -4 addr show dev "$BRIDGE_IFACE" | awk '{print $4}' | cut -d/ -f1)
    if [ -n "$MY_IP" ]; then
      echo "[DEBUG] BRIDGE MODE – IP attribuée : $MY_IP"
      break
    fi
    echo "[ATTENTE] Pas d'IP sur $BRIDGE_IFACE, tentative $i/30..."
    sleep 1
  done

  if [ -z "$MY_IP" ]; then
    echo "[ERREUR] Aucune IP détectée sur l’interface $BRIDGE_IFACE après 30 secondes."
    ip a show "$BRIDGE_IFACE"
    exit 1
  fi

  create_public_ip "$MY_IP"

  sed -i "/ubuntu-jammy/d" /etc/hosts
  sed -i "/$(hostname)/d" /etc/hosts

  echo "PRIMARY_IP=$MY_IP" >> /etc/environment
  echo "[DEBUG] Interface bridge utilisée : $BRIDGE_IFACE"
  echo "[DEBUG] BRIDGE MODE – IP attribuée : $MY_IP"
  exit 0
fi


# ====== NAT MODE ======
MY_IP="$(ip route | grep "^$IP_NW" | awk '{print $NF}')"
MY_NETWORK="$IP_NW"

create_public_ip "$MY_IP"

# Nettoyage de /etc/hosts
sed -i "/ubuntu-jammy/d" /etc/hosts
sed -i "/$(hostname)/d" /etc/hosts

echo "PRIMARY_IP=$MY_IP" >> /etc/environment

# Ajout des autres hôtes si NAT
echo "${MY_NETWORK}.${MASTER_IP_START} controlplane" >> /etc/hosts
for i in $(seq 1 "$NUM_WORKER_NODES"); do
  ip="${MY_NETWORK}.$((NODE_IP_START + i))"
  echo "$ip node0${i}" >> /etc/hosts
done
