# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# =============================
# Configuration globale
# =============================

# Mode de déploiement :
BUILD_MODE = (ENV['BUILD_MODE'] || "BRIDGE_STATIC").upcase

# Image Ubuntu 
#UBUNTU_BOX = ENV['UBUNTU_BOX'] || "noble64-updated" # Ubuntu 24.04 par défaut
UBUNTU_BOX = ENV['UBUNTU_BOX'] || "jammy64-updated" # Ubuntu 22.04 par défaut

# Nom du cluster utilisé pour préfixer les noms de VMs
CLUSTER_NAME = ENV['CLUSTER_NAME'] || "k8s"

# CNI : cillium ou flannel
CNI_PLUGIN = ENV['CNI_PLUGIN'] || "cilium-encryption-mtls"

# Version Kubernetes
K8S_VERSION = ENV['K8S_VERSION'] || "1.32"

# CONTAINER_RUNTIME : "containerd" | "docker"
# - "containerd" : installe containerd depuis les dépôts de la distribution
# - "docker"     : installe Docker Engine + containerd.io depuis les dépôts Docker
CONTAINER_RUNTIME = ENV['CONTAINER_RUNTIME'] || "docker"

# Nombre de controlplane (multi masternode)
NUM_CONTROLPLANE = (ENV['NUM_CONTROLPLANE'] || 1).to_i

#Virtual IP du point d’entrée du cluster
CONTROLPLANE_VIP = ENV['CONTROLPLANE_VIP']

# Nombre de nœuds workers à créer
NUM_WORKER_NODES = (ENV['NUM_WORKER_NODES'] || 1).to_i

# Nombre de nœuds extra à créer (sans kubernetes)
NUM_EXTRA_NODES = (ENV['NUM_EXTRA_NODES'] || 0).to_i

# Paramètres réseau utilisés les modes BRIDGE_STATIC et NAT
IP_START = ENV['IP_START'] || "192.168.1.200" # Début des IPs statiques

# If VIP_CONTROLPLANE is not set
$vip_adjustment_done = false
if NUM_CONTROLPLANE > 1 && (ENV['CONTROLPLANE_VIP'].nil? || ENV['CONTROLPLANE_VIP'].strip.empty?) && !$vip_adjustment_done
  CONTROLPLANE_VIP = IP_START
  # Décale IP_START de +1 pour ne pas chevaucher la VIP
  base = IP_START.rpartition('.')[0]
  last = IP_START.rpartition('.')[2].to_i + 1
  IP_START = "#{base}.#{last}"
  # puts "ℹ️ VIP not specified — using #{CONTROLPLANE_VIP} as CONTROLPLANE_VIP and shifting IP_START to #{IP_START}"
  $vip_adjustment_done = true
end

def static_ip(offset)
  base = IP_START.rpartition('.')[0]
  last = IP_START.rpartition('.')[2].to_i + offset
  return "#{base}.#{last}"
end

def get_bridge_adapter()
  iface = %x{ip route | grep default | awk '{print $5}' | grep -Ev 'tun0|docker0|virbr0|br-' | head -n1}.chomp
  return iface
end


def maybe_wait_bridge_dyn()
  sleep 2 if BUILD_MODE == "BRIDGE_DYN"
end

# === Helper pour générer une MAC unique (VirtualBox prefix)
def generate_mac()
  "080027%06x" % rand(0xffffff)
end

# Création d'une paire de clé ssh pour le cluster
require 'fileutils'
KEY_DIR = File.join(Dir.pwd, "ssh-keys")
PRIVATE_KEY_PATH = File.join(KEY_DIR, "id_rsa_#{CLUSTER_NAME}")
PUBLIC_KEY_PATH = File.join(KEY_DIR, "id_rsa_#{CLUSTER_NAME}.pub")
if ARGV.include?("up") || ARGV.include?("provision")
  if !File.exist?(PRIVATE_KEY_PATH) || !File.exist?(PUBLIC_KEY_PATH)
    puts "🔐 Generating SSH key pair for cluster '#{CLUSTER_NAME}'..."
    FileUtils.mkdir_p(KEY_DIR)
    system("ssh-keygen -t rsa -b 2048 -f #{PRIVATE_KEY_PATH} -N '' -q")
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = UBUNTU_BOX
  config.vm.boot_timeout = 900
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant"
  # config.vm.synced_folder ".", "/vagrant", mount_options: ["ro"]
  # config.vm.synced_folder "./opt-labs", "/opt/labs"

  # =============================
  # VM HAProxy pour VIP Kubernetes (uniquement si multi-controlplane)
  # =============================

  if BUILD_MODE == "BRIDGE_DYN" && NUM_CONTROLPLANE > 1
    abort("❌ Multi-controlplane mode is not supported with BUILD_MODE=BRIDGE_DYN.\n" \
          "➡️  Please use bridge_static or nat.")
  end

  if NUM_CONTROLPLANE > 1 # On n'installe une VM HAProxy que s'il y a plus d'un controlplane
    config.vm.define "#{CLUSTER_NAME}-haproxy-vip" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "#{CLUSTER_NAME}-haproxy-vip"
        vb.memory = 512
        vb.cpus = 1
      end
      node.vm.hostname = "#{CLUSTER_NAME}-haproxy-vip"

      if BUILD_MODE == "BRIDGE_DYN"
        node.vm.network :public_network, bridge: get_bridge_adapter()
      elsif BUILD_MODE == "BRIDGE_STATIC"
        node.vm.network :public_network, ip: CONTROLPLANE_VIP, bridge: get_bridge_adapter()
      else # NAT
        node.vm.network :private_network, ip: CONTROLPLANE_VIP
        node.vm.network "forwarded_port", guest: 22, host: 2709
      end

      node.vm.provision "haproxy", type: "shell", path: "scripts/02-haproxy-vip.sh",
        env: {
          "CONTROLPLANE_VIP" => CONTROLPLANE_VIP,
          "NUM_CONTROLPLANE" => NUM_CONTROLPLANE.to_s,
          "IP_START" => IP_START
        }
      node.vm.provision "08-ssh-access", type: "shell", path: "scripts/08-ssh-access.sh", env: {"CLUSTER_NAME" => CLUSTER_NAME}
    end
  end

  # ================================
  # Noeuds controlplane single/multi
  # ================================

  (1..NUM_CONTROLPLANE).each do |i|

    config.vm.define "#{CLUSTER_NAME}-controlplane0#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "#{CLUSTER_NAME}-controlplane0#{i}"
        vb.memory = 4096
        vb.cpus = 2
      end
      node.vm.hostname = "#{CLUSTER_NAME}-controlplane0#{i}"

      if BUILD_MODE == "BRIDGE_DYN"
        #node.vm.network :public_network, bridge: get_bridge_adapter()
        node.vm.network :public_network,
          bridge: get_bridge_adapter(),
          use_dhcp_assigned_default_route: true,
          mac: generate_mac(),
          auto_config: false
      elsif BUILD_MODE == "BRIDGE_STATIC"
        node.vm.network :public_network, ip: static_ip(i-1), bridge: get_bridge_adapter()
      else # NAT
        node.vm.network :private_network, ip: static_ip(i-1)
        node.vm.network "forwarded_port", guest: 22, host: 2710 + i
      end

      # === Provisioning par scripts ===
      # node.vm.provision "01-base-setup", type: "shell", path: "scripts/01-base-setup.sh"
      node.vm.provision "01-base-setup", type: "shell", path: "scripts/01-base-setup.sh",  env: {"BUILD_MODE" => BUILD_MODE}
      if CONTAINER_RUNTIME == "docker"
        node.vm.provision "03-containerd-docker", type: "shell", path: "scripts/03-containerd-docker.sh"
      else
        node.vm.provision "03-containerd", type: "shell", path: "scripts/03-containerd.sh"
      end
      node.vm.provision "04-kubernetes", type: "shell", path: "scripts/04-kubernetes.sh", env: {"K8S_VERSION" => K8S_VERSION}

      if i == 1 # First (or unique) controlplane
        node.vm.provision "05-first-controlplane", type: "shell", path: "scripts/05-first-controlplane-join.sh",
          env: { "CNI_PLUGIN" => CNI_PLUGIN,
          "K8S_VERSION" => K8S_VERSION,
          "CLUSTER_NAME" => CLUSTER_NAME,
          "CONTROLPLANE_VIP" => CONTROLPLANE_VIP,
          "NUM_CONTROLPLANE" => NUM_CONTROLPLANE,
          "IP_START" => IP_START}
      end
      if NUM_CONTROLPLANE > 1 && i > 1 # Other controlplanes
        node.vm.provision "06-secondary-controlplane", type: "shell", path: "scripts/06-secondary-controlplane-join.sh",
          env: {"CLUSTER_NAME" => CLUSTER_NAME, "CONTROLPLANE_VIP" => CONTROLPLANE_VIP}
      end
      node.vm.provision "08-ssh-access", type: "shell", path: "scripts/08-ssh-access.sh", env: {"CLUSTER_NAME" => CLUSTER_NAME}
    end
    
    ## 📝 Export des variables dans un fichier que les scripts peuvent sourcer
    ## Utilisation dans node : [ -f /etc/env-k8s-vars ] && source /etc/env-k8s-vars
    # config.vm.provision "shell", privileged: true, inline: <<-SHELL
    #   cat <<EOF > /etc/env-k8s-vars
    # export CONTROLPLANE_VIP=#{vip}
    # export K8S_VERSION=#{k8s_version}
    # export POD_CIDR=#{pod_cidr}
    # export BASE_IP=#{base_ip}
    # export START_OCTET=#{start_octet}
    # export NUM_CONTROLPLANE=#{num_controlplane}
    # export CONTAINER_RUNTIME=#{container_runtime}
    # EOF
    #   chmod +x /etc/env-k8s-vars
    # SHELL
  end

  # =============================
  # Noeuds workers
  # =============================
  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "#{CLUSTER_NAME}-node0#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "#{CLUSTER_NAME}-node0#{i}"
        vb.memory = 4096
        vb.cpus = 1
      end
      node.vm.hostname = "#{CLUSTER_NAME}-node0#{i}"

      if BUILD_MODE == "BRIDGE_DYN"
        #node.vm.network :public_network, bridge: get_bridge_adapter()
        node.vm.network :public_network,
          bridge: get_bridge_adapter(),
          use_dhcp_assigned_default_route: true,
          mac: generate_mac(),
          auto_config: false
      elsif BUILD_MODE == "BRIDGE_STATIC"
        node.vm.network :public_network, ip: static_ip(i-1+NUM_CONTROLPLANE), bridge: get_bridge_adapter()
      else # NAT
        node.vm.network :private_network, ip: static_ip(i-1+NUM_CONTROLPLANE)
        node.vm.network "forwarded_port", guest: 22, host: 2720 + i
      end

      # === Provisioning par scripts ===
      # node.vm.provision "01-base-setup", type: "shell", path: "scripts/01-base-setup.sh"
      node.vm.provision "01-base-setup", type: "shell", path: "scripts/01-base-setup.sh",  env: {"BUILD_MODE" => BUILD_MODE}
      if CONTAINER_RUNTIME == "docker"
        node.vm.provision "03-containerd-docker", type: "shell", path: "scripts/03-containerd-docker.sh"
      else
        node.vm.provision "03-containerd", type: "shell", path: "scripts/03-containerd.sh"
      end
      node.vm.provision "04-kubernetes", type: "shell", path: "scripts/04-kubernetes.sh", env: {"K8S_VERSION" => K8S_VERSION}
      node.vm.provision "07-worker", type: "shell", path: "scripts/07-worker.sh", env: {"CLUSTER_NAME" => CLUSTER_NAME}
      node.vm.provision "08-ssh-access", type: "shell", path: "scripts/08-ssh-access.sh", env: {"CLUSTER_NAME" => CLUSTER_NAME}
    end
  end
  
  # =============================
  # Noeuds sans kubernetes (extra)
  # =============================
  (1..NUM_EXTRA_NODES).each do |i|
    config.vm.define "#{CLUSTER_NAME}-extra0#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "#{CLUSTER_NAME}-extra0#{i}"
        vb.memory = 2048
        vb.cpus = 1
      end
      node.vm.hostname = "#{CLUSTER_NAME}-extra0#{i}"

      if BUILD_MODE == "BRIDGE_DYN"
        #node.vm.network :public_network, bridge: get_bridge_adapter()
        node.vm.network :public_network,
          bridge: get_bridge_adapter(),
          use_dhcp_assigned_default_route: true,
          mac: generate_mac(),
          auto_config: false
      elsif BUILD_MODE == "BRIDGE_STATIC"
        node.vm.network :public_network, ip: static_ip(i-1+NUM_CONTROLPLANE+NUM_WORKER_NODES), bridge: get_bridge_adapter()
      else
        node.vm.network :private_network, ip: static_ip(i-1+NUM_CONTROLPLANE+NUM_WORKER_NODES)
        node.vm.network "forwarded_port", guest: 22, host: 2730 + i
      end

      # === Provisioning par scripts ===
      # node.vm.provision "01-base-setup", type: "shell", path: "scripts/01-base-setup.sh"
      node.vm.provision "01-base-setup", type: "shell", path: "scripts/01-base-setup.sh",  env: {"BUILD_MODE" => BUILD_MODE}
      node.vm.provision "08-ssh-access", type: "shell", path: "scripts/08-ssh-access.sh", env: {"CLUSTER_NAME" => CLUSTER_NAME}
      node.vm.provision "09-extra-node", type: "shell", path: "scripts/09-extra-node.sh"
    end
  end

  # =============================
  # Synchronisation du fichier /etc/hosts à la fin
  # =============================
  if ARGV.include?("up") || ARGV.include?("provision")
    at_exit do
      puts "🛠️ Synchronizing the /etc/hosts file across all virtual machines..."
      nodes = []
      nodes << "#{CLUSTER_NAME}-haproxy-vip" if NUM_CONTROLPLANE > 1
      nodes += (1..NUM_CONTROLPLANE).map { |j| "#{CLUSTER_NAME}-controlplane0#{j}" }
      nodes += (1..NUM_WORKER_NODES).map { |k| "#{CLUSTER_NAME}-node0#{k}" }
      nodes += (1..NUM_EXTRA_NODES).map { |l| "#{CLUSTER_NAME}-extra0#{l}" }

      nodes.each do |vm|
        puts "📤 Upload du fichier hosts vers #{vm}"
        system("vagrant upload hosts /tmp/hosts.tmp #{vm}")
        system("vagrant ssh #{vm} -c 'sudo cp /tmp/hosts.tmp /etc/hosts && echo [OK] /etc/hosts mis à jour' -- -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null")
      end
      # Affiché à la toute fin du provisionnement
      puts "🏁 🏁 🏁 CLUSTER IS READY 🏁 🏁 🏁"
    end  
  elsif ARGV.include?("destroy")
    # Ici aussi, hors at_exit
    puts "🧹 CLEANUP – All VMs will be DESTROYED"
  end
end
