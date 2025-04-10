#!/bin/bash

# Active l'authentification par mot de passe SSH (utile pour ssh-copy-id par exemple)
sed -i 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config
sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config

# Vérifie si le service SSH existe, sinon installe openssh-server
if systemctl list-units --type=service | grep -q ssh; then
  systemctl restart ssh
else
  echo "[!] Le service SSH n'a pas été trouvé. Tentative d'installation..."
  apt-get update && apt-get install -y openssh-server
  systemctl enable ssh
  systemctl start ssh
fi