#!/bin/bash

function InstallPackage() {
   sudo pacman -S --noconfirm --needed "$1"
}

function installAUR() {
   mkdir -p ~/Desktop/repos
   cd ~/Desktop/repos
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   sudo makepkg -si --noconfirm
}

function installBlackArch() {
   mkdir -p ~/Desktop/repos/BlackArch
   cd ~/Desktop/repos/BlackArch
   curl -O https://blackarch.org/strap.sh
   chmod +x strap.sh
   sudo ./strap.sh
   InstallPackage blackarch
}

function setUpHyperland() {
   mkdir -p ~/Downloads
   cd ~/Downloads
   git clone https://gitlab.com/stephan-raabe/dotfiles.git
   cd dotfiles
   ./install.sh
}

function main() {
    InstallPackage git  # Install git at the beginning
    installAUR  
    installBlackArch
    setUpHyperland
}   

main
