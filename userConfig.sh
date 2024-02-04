#!/bin/bash

function InstallPackage() {
   echo "$password" | sudo -S pacman -S --noconfirm --needed "$1"
}

function installAUR() {
   password=$1
   InstallPackage git
   echo "$password" | sudo -S mkdir -p ~/Desktop/repos
   cd ~/Desktop/repos
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   echo "$password" | sudo -S makepkg -si --noconfirm
}

function installBlackArch() {
   password=$1
   InstallPackage curl
   echo "$password" | sudo -S mkdir -p ~/Desktop/repos/BlackArch
   cd ~/Desktop/repos/BlackArch
   curl -LO https://blackarch.org/strap.sh
   chmod +x strap.sh
   echo "$password" | sudo -S ./strap.sh
}

function setUpHyperland() {
   mkdir -p ~/Downloads
   cd ~/Downloads
   read -p "Press Enter to continue with Hyperland setup..."
   git clone https://gitlab.com/stephan-raabe/dotfiles.git
   cd dotfiles
   read -p "Press Enter to start the installation..."
   ./install.sh
}

function main() {
    read -s -p "Enter sudo password: " password
    InstallPackage git  # Install git at the beginning
    installAUR  
    sleep 50
    installBlackArch
    sleep 50
    setUpHyperland
    sleep 50
}   

main
