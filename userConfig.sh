#!/bin/bash

function installAUR() {
   mkdir -p ~/Desktop/repos
   cd ~/Desktop/repos
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   makepkg -s  # This will install dependencies
   makepkg -f    # This will build the package
   package="$(ls | grep paru-bin | grep -v debug | head -n 1)" 
   sudo pacman -U "$package"
   paru  # Replace package_name with the actual package name generated
   cd ..
   rm -rf paru
}

function setUpHyperland() {
   mkdir -p ~/Downloads/Hyprland-Raabe
   cd ~/Downloads/Hyprland-Raabe 
   curl -O https://gitlab.com/stephan-raabe/installer/-/raw/main/installer.sh

   sudo chmod +x installer.sh

   echo "$(pwd)"


   session="HyperLand"
   install_script="installer.sh"
   window=0

   tmux new-session -d -s "HyperLand" || { echo "error on new session"; }

   tmux rename-window -t "HyperLand:0" "HyperLand" || { echo "error on rename session"; }

   tmux send-keys -t "HyperLand:0" "./installer.sh; exit;" C-m || { echo "error on sendkeys to session"; }

   tmux attach-session -t "HyperLand" || { echo "error on attach session"; }
   
   # Wait for the installation script to complete (you may adjust the sleep duration)
   sleep 5

   # Check if the installation script has completed successfully
   if tmux wait-for -S "HyperLand:complete"; then
      echo "Installation completed successfully."
   else
      echo "Installation failed."
   fi

   # Kill the tmux session
   tmux kill-session -t "HyperLand"

}

function main() {

   echo "Please enter your sudo sudo -Sv password:"
   sudo -Sv
   installAUR

   setUpHyperland 
}   

main
