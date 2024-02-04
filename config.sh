#!/bin/bash

device="$1"

function InstallPackage() {
   pacman -S --noconfirm --needed "$1"
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
   # Installing GRUB dependences
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
   InstallPackage "sudo"
   InstallPackage "visudo"

   cp /etc/sudoers /tmp/sudoers.tmp
   echo "%wheel ALL=(ALL:ALL) ALL" >> /tmp/sudoers.tmp
   visudo -c -f /tmp/sudoers.tmp
   if [ $? -eq 0 ]; then
      cp /tmp/sudoers.tmp /etc/sudoers
   else
      echo "sudoers file has a syntax error. Not replacing the original file."
   fi
}



function endMountingPartitions() {
   mkdir -p "/boot/EFI"

   mount "${device}1" "/boot/EFI"       # Mount ESP to /mnt/boot
}


function main() {
   endMountingPartitions

   setUpInitramfs
   setTimeZone
   setUpHostname
   setUpLanguage
   setUpKeyboardLayout
   installAndSetUpSudo
   setUpRoot
   setUpUsers

   setUpGRUB
}

main



#!/bin/bash

function setUpNetwork() {
   sudo systemctl start NetworkManager.service
   sudo systemctl enable NetworkManager
   sudo systemctl start wpa_supplicant.service
   sudo systemctl enable wpa_supplicant.service
}

function installAUR() {
   sudo pacman -S git
   mkdir -p ~/Desktop/repos
   cd ~/Desktop/repos
   git clone https://aur.archlinux.org/paru-bin.git
   cd paru-bin
   makepkg -si
}

function installBlackArch() {
   mkdir -p ~/Desktop/repos/BlackArch
   cd ~/Desktop/repos/BlackArch
   curl -O https://blackarch.org/strap.sh
   chmod +x strap.sh
   sudo ./strap.sh
   sudo pacman -Syu
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

# Function to install Kitty
function install_kitty() {
    sudo pacman -S kitty
}

# Function to install Firefox
function install_firefox() {
    sudo pacman -S firefox
}

# Function to install Locate
function install_locate() {
    sudo pacman -S locate
}

# Function to install zsh for all users and set it as default shell
function install_zsh() {
    sudo pacman -S zsh

    # Change the shell for all users
    users=$(cut -d: -f1 /etc/passwd)
    for user in $users
    do
        sudo chsh -s $(which zsh) $user
    done

    # Create .zshrc in root and make a link for all users
    cd /tmp
    curl -LO https://raw.githubusercontent.com/Thelag55/ArchInstalling/main/.zshrc
    sudo cp .zshrc /root/.zshrc
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            sudo ln -s /root/.zshrc "$user_home/.zshrc"
        fi
    done
}

# Function to install zsh plugins
function install_zsh_plugins() {
    sudo pacman -S zsh-syntax-highlighting zsh-autosuggestions
    sudo mkdir -p /usr/share/zsh-sudo
    cd /usr/share/zsh-sudo
    sudo curl -LO https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh
}

# Function to update system files
function update_system_files() {
    sudo updatedb
}

# Function to install bat and lsd
function install_bat_lsd() {
    sudo pacman -S lsd bat
}

# Function to install Hack Nerd Fonts
function install_nerd_fonts() {
    sudo mkdir -p /usr/share/fonts
    cd /usr/share/fonts
    sudo curl -LO https://github.com/Thelag55/ArchInstalling/blob/main/Hack.zip
    sudo unzip Hack.zip
    sudo rm Hack.zip
}

# Function to configure and install kitty
function config_install_kitty() {
    sudo pacman -S kitty
    sudo mkdir -p /root/.config/kitty
    cd /root/.config/kitty
    sudo curl -LO https://raw.githubusercontent.com/Thelag55/ArchInstalling/main/kitty.conf
    sudo curl -LO https://raw.githubusercontent.com/Thelag55/ArchInstalling/main/color.ini

    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            sudo mkdir -p "$user_home/.config/kitty"
            sudo ln -s /root/.config/kitty/kitty.conf "$user_home/.config/kitty/kitty.conf"
            sudo ln -s /root/.config/kitty/color.ini  "$user_home/.config/kitty/color.ini"
        fi
    done
}

# Function to install PowerLevel 10k
function install_powerlevel_10k() {
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
    zsh

    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            sudo mkdir -p "$user_home/.config/powerlevel10k"
            sudo ln -s /root/.config/powerlevel10k/.p10k.zsh "$user_home/.config/powerlevel10k/.p10k.zsh"
        fi
    done
}

# Function to install fzf
function install_fzf() {
    sudo pacman -S fzf
}

# Function to install neovim with NvChad
function install_neovim_nvchad() {
    sudo pacman -S neovim
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
}

# Function to install mdcat
function install_mdcat() {
    sudo pacman -S mdcat
}

function main2() {
   setUpNetwork
   read -p "Read main user name: " mainUser
   su $mainUser -c "installAUR"
   su $mainUser -c "installBlackArch"
   su $mainUser -c "setUpHyperland"
   install_kitty
   install_firefox
   install_locate
   install_zsh
   install_zsh_plugins
   update_system_files
   install_bat_lsd
   install_nerd_fonts
   config_install_kitty
   install_powerlevel_10k
   install_fzf
   install_neovim_nvchad
   install_mdcat
}

main2

