function setUpNetwork() {
   sudo su
   systemctl start NetworkManager.service
   systemctl enable NetworkManager
   systemctl start wpa_supplicant.service
   systemctl enable wpa_supplicant.service
}

function installAUR() {
   pacman -S git
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

function main() {
   sudo su
   setUpNetwork
   read -p "Read main user name: " mainUser
   su $mainUser
   installAUR
   installBlackArch
   setUpHyperland
   sudo su
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

main
