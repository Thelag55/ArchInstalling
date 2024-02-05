#!/bin/bash

function InstallPackage() {
   echo "$password" | sudo -S pacman -S --noconfirm --needed "$1"
}

function installAUR() {
   read -p "Before AUR Installing" test
   InstallPackage git
   mkdir -p ~/Desktop/repos
   cd ~/Desktop/repos
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   makepkg -si --noconfirm
   read -p "After AUR Installing" test
}

function installBlackArch() {
   read -p "Before blackArch Installing" test
   password=$1
   InstallPackage curl
   mkdir -p ~/Desktop/repos/BlackArch
   cd ~/Desktop/repos/BlackArch
   curl -O https://blackarch.org/strap.sh
   chmod +x strap.sh
   echo "$password" | sudo -S ./strap.sh
   read -p "After blackArch Installing" test
}

function setUpHyperland() {
   read -p "Before HyperLand Installing" test
   mkdir -p ~/Downloads
   cd ~/Downloads
   read -p "Press Enter to continue with Hyperland setup..."
   git clone https://gitlab.com/stephan-raabe/dotfiles.git
   cd dotfiles
   read -p "Press Enter to start the installation..."

   session="HyperLand"
   passwd="Tiburon55"
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

   read -p "After HyperLand Installing" test
}

function main() {
    read -s -p "Enter sudo password: " password
    InstallPackage git  # Install git at the beginning
    installAUR 
    installBlackArch
    setUpHyperland
}   

main
