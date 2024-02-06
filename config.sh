#!/bin/bash

device="$1"

# Define all functions here...

#!/bin/bash

installDependencies() {
    for pkg in "$@"; do
        echo "Installing $pkg..."
        sudo pacman -Sy --noconfirm --needed "$pkg"
        if [ $? -eq 0 ]; then
            echo "Successfully installed $pkg."
        else
            echo "Failed to install $pkg."
        fi
    done
}


function installAllDependences() {
   
   installDependencies sudo visudo grub efibootmgr dosfstools os-prober mtools kitty firefox mlocate zsh dos2unix zsh-syntax-highlighting zsh-autosuggestions lsd bat unzip fzf neovim git tmux curl npm

}

function setUpInitramfs() {
   mkinitcpio -P
}

function setTimeZone() {
   sudo ln -sf "/usr/share/zoneinfo/Europe/Madrid" "/etc/localtime"
}

function setUpRoot() {
   echo "Choose the password for the user root"
   passwd
   while [ $? -ne 0 ]; do
      passwd
   done
}

function createUser() {
   useradd -m -G wheel "$1"
   passwd "$1"
   while [ $? -ne 0 ]; do
      passwd "$1"
   done
}

function setUpUsers() {
   while true; do
      echo "Do you want to create a new User? [Y/n]:"
      read answer
      if [ "$answer" != "n" ]; then
         read -p "Enter username: " name
         createUser "$name"
      else
         break
      fi
   done
}

function setUpGRUB() {
   # Installing GRUB dependencies
   pacman -S --noconfirm --needed grub efibootmgr dosfstools os-prober mtools
   
   grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
   mkdir /boot/grub/locale
   cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
   grub-mkconfig -o /boot/grub/grub.cfg
}

function setUpHostname() {
   echo "ArchMachine" > "/etc/hostname"
}

function setUpLanguage() {
   echo  "LANG=en_US.UTF-8" > "/etc/locale.conf"
}

function setUpKeyboardLayout() {
   ## Keyboard layout is automated and it will use the Spanish One
   sed -i "/en_US.UTF-8 UTF-8/s/^#//" "/etc/locale.gen" # Here unlock the US one
   sed -i "/es_ES.UTF-8 UTF-8/s/^#//" "/etc/locale.gen" # Here unlock the ES one
   locale-gen
   echo "KEYMAP=es" >> "/etc/vconsole.conf"
}

function installAndSetUpSudo() {
   cp /etc/sudoers /tmp/sudoers.tmp
   echo "%wheel ALL=(ALL:ALL) ALL" >> /tmp/sudoers.tmp
   visudo -c -f /tmp/sudoers.tmp
   if [ $? -eq 0 ]; then
      cp /tmp/sudoers.tmp /etc/sudoers
   else
      echo "sudoers file has a syntax error. Not replacing the original file."
   fi
}

function updatePackageManager() {
    sudo pacman -Syu
}

function endMountingPartitions() {
   mkdir -p "/boot/EFI"

   mount "${device}1" "/boot/EFI"       # Mount ESP to /mnt/boot
}

function main() {
   endMountingPartitions

   setUpInitramfs
   
   updatePackageManager
   installAllDependences
   setTimeZone
   setUpHostname
   setUpLanguage
   setUpKeyboardLayout
   installAndSetUpSudo
   setUpRoot
   setUpUsers

   setUpGRUB
}

function setUpNetwork() {
   sudo systemctl start NetworkManager.service
   sudo systemctl enable NetworkManager
   sudo systemctl start wpa_supplicant.service
   sudo systemctl enable wpa_supplicant.service
}

# Function to install Kitty


# Function to install Firefox


# Function to install Locate


# Function to install zsh for all users and set it as the default shell
function setUpZshForAllUsers() {

    # Change the shell for root
    sudo chsh -s /usr/bin/zsh root
    # Change the shell for all users
   users=($(find /home/ -maxdepth 1 -type d))
   users=( $(echo "${users[@]}" | sed 's/\/home\///g') )
   for user in "${users[@]}"; 
    do
        sudo chsh -s $(which zsh) $user
    done

    # Create .zshrc in root and make a link for all users
    cd /tmp
    curl -LO https://raw.githubusercontent.com/Thelag55/ArchInstalling/main/.zshrc
    dos2unix .zshrc
    mkdir -p /usr/share/share
    sudo cp .zshrc /usr/share/share

    #Link to root
    ln -s /usr/share/share/.zshrc /root/.zshrc
    #Link to users
    users=($(find /home/ -maxdepth 1 -type d))
    for user_home in "${users[@]}"; do
        if [ -d "$user_home" ]; then
            ln -s /usr/share/share/.zshrc "$user_home/.zshrc"
        fi
    done
}

# Function to install zsh plugins
function installZshPlugins() {
    sudo mkdir -p /usr/share/zsh-sudo
    cd /usr/share/zsh-sudo
    sudo curl -LO https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh
}

# Function to update system files
function updateSystemFiles() {
    sudo updatedb
}

# Function to install bat and lsd

# Function to install Hack Nerd Fonts
function instalNerdFonts() {
    sudo mkdir -p /usr/share/fonts
    cd /usr/share/fonts
    sudo curl -O https://raw.githubusercontent.com/Thelag55/ArchInstalling/main/Hack.zip
    sudo unzip Hack.zip
    sudo rm Hack.zip
}

# Function to configure and install kitty
function configKitty() {
    mkdir -p /usr/share/share
    cd /usr/share/share
    sudo mkdir -p /root/.config/kitty
    curl -LO https://raw.githubusercontent.com/Thelag55/ArchInstalling/main/kitty.conf
    curl -LO https://raw.githubusercontent.com/Thelag55/ArchInstalling/main/color.ini
    dos2unix kitty.conf
    dos2unix color.ini

   #Link to root
   ln -s /usr/share/share/kitty.conf "/root/.config/kitty/kitty.conf"
   ln -s /usr/share/share/color.ini  "/root/.config/kitty/color.ini"
   #Link to all users
    users=($(find /home/ -maxdepth 1 -type d))
    for user_home in "${users[@]}"; do
        if [ -d "$user_home" ]; then
            sudo mkdir -p "$user_home/.config/kitty"
            ln -s /root/.config/kitty/kitty.conf "$user_home/.config/kitty/kitty.conf"
            ln -s /root/.config/kitty/color.ini  "$user_home/.config/kitty/color.ini"
        fi
    done
}

# Function to install PowerLevel 10k
function installPowerlevel10k() {
    
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/share/powerlevel10k

   session="PowerLevel10k"

   tmux new-session -d -s "$session"

   window=0
   tmux rename-window -t "$session:$window" 'HyperLand'
   tmux send-keys -t "$session:$window" "zsh; echo 'The script is over'; exit" C-m

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



    users=($(find /home/ -maxdepth 1 -type d))
    for user_home in "${users[@]}"; do
        if [ -d "$user_home" ]; then
            sudo mkdir -p "$user_home/.config/powerlevel10k"
            sudo ln -s /root/.config/powerlevel10k/.p10k.zsh "$user_home/.config/powerlevel10k/.p10k.zsh"
        fi
    done
}


# Function to install neovim with NvChad
function installNvchad() {
   git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
}

function userConfig() {
   users=($(find /home/ -maxdepth 1 -type d))
   users=( $(echo "${users[@]}" | sed 's/\/home\///g') )
   echo "This are the available users: "
   for user in "${users[@]}"; do echo "[+] $user";  done

   while true; do
      read -p "Write the main user name: " mainUser
      if [[ " ${users[@]} " =~ " ${mainUser} " ]]; then
         break
      else
         echo "Invalid user. Please try again."
      fi
   done

   sudo curl -LO https://raw.githubusercontent.com/Thelag55/ArchInstalling/main/userConfig.sh
   sudo chmod +x ./userConfig.sh
   mv userConfig.sh /home/$mainUser
   su -l $mainUser -c "./userConfig.sh"
}

function main2() {
   setUpNetwork

   userConfig

   configKitty
   setUpZshForAllUsers
   installZshPlugins
   updateSystemFiles
   instalNerdFonts
   installNvchad
   installPowerlevel10k
}

main
main2
