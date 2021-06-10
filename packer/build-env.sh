#!/bin/bash -e
# configure Ubuntu-based machines with everything needed for development
# of IOHK Haskell code

# ensure apt does not try to 'Dialog' with a user
export DEBIAN_FRONTEND=noninteractive

# for emacs27
sudo add-apt-repository -y ppa:kelleyk/emacs

# install neovim
sudo add-apt-repository ppa:neovim-ppa/stable

# Update the package list
sudo -E apt-get update

# Ugrade image
sudo -E apt-get upgrade -y

# install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo apt-add-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) edge"

# TODO trim down the list of packages to install as most of them should be provided by nix
sudo -E apt-get install -y apt-transport-https  ca-certificates  curl  software-properties-common git \
     emacs27-nox gnupg2 libtinfo-dev tmux graphviz wget jq bzip2 readline-common \
     neovim inotify-tools silversearcher-ag fd-find ripgrep \
     build-essential curl language-pack-en docker-ce

# install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# prefer ipv4 connections over ipv6
echo "precedence ::ffff:0:0/96  100" | sudo tee -a /etc/gai.conf

# this is needed for proper gpg-agent forwarding to work
sudo tee -a /etc/ssh/sshd_config > /dev/null <<EOF
StreamLocalBindUnlink yes
EOF

# install & configure nix
curl -o install-nix-2.3.10 https://releases.nixos.org/nix/nix-2.3.10/install
curl -o install-nix-2.3.10.asc https://releases.nixos.org/nix/nix-2.3.10/install.asc
gpg --keyserver keys.gnupg.net --recv-keys B541D55301270E0BCF15CA5D8170B4726D7198DE
gpg --verify ./install-nix-2.3.10.asc
sh ./install-nix-2.3.10 --daemon

# to update environment variables with installed nix stuff
. /etc/profile.d/nix.sh

cat | sudo tee /etc/nix/nix.conf <<EOF
max-jobs = 6
cores = 0
trusted-users = root curry
keep-derivations = true
keep-outputs = true
substituters = https://cache.nixos.org https://hydra.iohk.io https://iohk.cachix.org
trusted-public-keys = iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo= hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
EOF

# configure unattended upgrades
distro_id=$(lsb_release -is)
distro_codename=$(lsb_release -cs)

cat | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}";
  "${distro_id}:${distro_codename}-security";
  "${distro_id}:${distro_codename}-updates";
  "${distro_id}ESM:${distro_codename}";
}
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "05:38";
EOF

cat | sudo tee /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
