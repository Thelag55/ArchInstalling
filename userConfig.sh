#!/bin/bash

function installAUR() {
   password=$1
   read -p "Before install Aur" test
   mkdir -p ~/Desktop/repos
   cd ~/Desktop/repos
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   read -p "Before pkg Aur" test
   echo "$password" | sudo -S makepkg -si --noconfirm
   read -p "After pkg Aur" test
}

function setUpHyperland() {
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
    installAUR "$password"
    installBlackArch 
    #setUpHyperland
}   

main
