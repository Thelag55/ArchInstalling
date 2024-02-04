#!/bin/bash

function installAUR() {
   InstallPackage git
   mkdir -p ~/Desktop/repos
   cd ~/Desktop/repos
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   makepkg -si --noconfirm
}

function installBlackArch() {
   mkdir -p ~/Desktop/repos/BlackArch
   cd ~/Desktop/repos/BlackArch
   curl -O https://blackarch.org/strap.sh
   chmod +x strap.sh
   sudo ./strap.sh
   InstallPackage blackarch
   sudo pacman -Syu --noconfirm
}

function setUpHyperland() {
   mkdir ~/Downloads
   # 1.) Change into your Downloads folder
   cd ~/Downloads
   # 2.) Clone the dotfiles repository into the Downloads folder
   git clone https://gitlab.com/stephan-raabe/dotfiles.git
   # 3.) Change into the dotfiles folder
   cd dotfiles
   # 4.) Start the installation
   ./install.sh
}

function main() {
    installAUR  
    installBlackArch
    setUpHyperland
}   

main