#!/bin/bash

function InstallPackage() {
   echo "$password" | sudo -S pacman -S --noconfirm --needed "$1"
}

function installAUR() {
   InstallPackage git
   mkdir -p ~/Desktop/repos
   cd ~/Desktop/repos
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   makepkg -si --noconfirm
}

function installBlackArch() {
   InstallPackage curl
   mkdir -p ~/Desktop/repos/BlackArch
   cd ~/Desktop/repos/BlackArch
   curl -O https://blackarch.org/strap.sh
   chmod +x strap.sh
   echo "$password" | sudo -S ./strap.sh
}

function setUpHyperland() {
   InstallPackage tmux
   mkdir -p ~/Downloads
   cd ~/Downloads
   git clone https://gitlab.com/stephan-raabe/dotfiles.git
   cd dotfiles

   session="HyperLand"
   install_script="install.sh"

   tmux new-session -d -s "$session"

   window=0
   tmux rename-window -t "$session:$window" 'HyperLand'
   tmux send-keys -t "$session:$window" "./$install_script; echo 'The script is over'; exit" C-m

   tmux attach-session -t $session
   # Wait for the installation script to complete (you may adjust the sleep duration)
   sleep 5

   # Check if the installation script has completed successfully
   if tmux wait-for -S "$session:complete"; then
      echo "Installation completed successfully."
   else
      echo "Installation failed."
   fi

   # Kill the tmux session
   tmux kill-session -t "$session"

}

function main() {
    read -s -p "Enter sudo password: " password
    InstallPackage git  # Install git at the beginning
    installAUR 
    installBlackArch
    setUpHyperland
}   

main
