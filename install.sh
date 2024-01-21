#!/bin/bash


device=""

function InstallPackage() {
   pacman -S --noconfirm --needed "$1"
}
    
function setUpKeyboard() {
   loadkeys es
}

function setUpPartitions() {

   disk=$device

   # Create a new GPT partition table
   parted $disk --script mklabel gpt

   # Create an EFI System Partition (ESP) of 4GB
   parted $disk --script mkpart primary fat32 1MiB 5GiB

   # Set the ESP flag on the partition
   parted $disk --script set 1 esp on

   # Create a swap partition fixed at 16GB
   parted $disk --script mkpart primary linux-swap 5GiB 21GiB

   # Create a root partition ("/") using the remaining space
   parted $disk --script mkpart primary ext4 21GiB 100%

   # Print the partition information
   sudo parted $disk --script print
}

function formatPartitions() {

   disk=$device 

   mkfs.ext4 "${disk}3"

   mkfs.fat -F32 "${disk}1" 
}

function mountPartitions() {

   # Assuming /dev/sdx1 is the ESP, /dev/sdx2 is the swap, and /dev/sdx3 is the root ("/") partition
   disk=$device
   # Create mount points
   mkdir -p /mnt/boot
   mkdir -p /mnt
   mkdir -p /mnt/proc

   # Mount the partitions
   mount "${disk}1" /mnt/boot   # Mount ESP to /mnt/boot
   mkswap "${disk}2"            # Set up swap
   swapon "${disk}2"            # Activate swap
   mount "${disk}3" /mnt        # Mount root ("/") to /mnt

}

function createAndMountPartitions() {
   echo "Welcome to the auto set up"
   echo "$(sudo fdisk -l | grep sd)"
   echo "Choose which device you want to use (At least 50GiB)"
   devices=$(sudo fdisk -l | grep sd | awk '{print $2}' | sed "s/://") 
  
   read -p "Enter device: " device

   while [[ ! " ${devices[@]} " =~ " $device " ]]; do
      echo "Invalid device. Choose again:"
      read -p "Enter device: " device
   done

   setUpPartitions 
   formatPartitions 
   mountPartitions 
}

function checkError() {
   if [ $? -ne 0 ]; then
      echo "There was an error in the function $1"
   fi
}

function setUpGRUB() {
   grub-install $device
   grub-mkconfig -o /boot/grub/grub.cfg
}

function setUpHostname() {
   echo "ArchMachine" > /etc/hostname
}

function setUpKeyboardLayout() {
   ## Keyboard layout is automated and it will use the Spanish One
   sed -i "/en_US.UTF-8 UTF-8/s/^#//" /etc/locale.gen # Here unlock the US one
   sed -i "/es_ES.UTF-8 UTF-8/s/^#//" /etc/locale.gen # Here unlock the ES one
   locale-gen
   echo "KEYMAP=es" >> /etc/vconsole.conf
}

function installAndSetUpSudo() {
   InstallPackage "sudo"
   #We'll let a .aui file in case we ever need to back up
   if [[ ! -f /etc/sudoers.aui ]]; then
		cp -v /etc/sudoers /etc/sudoers.aui
		## Uncomment to allow members of group wheel to execute any command
		sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
   fi
}

function setUpRoot() {
   passwd
   while [ $? -ne 0 ]; do
      passwd
   done
}

function createUser() {
   useradd -m "$1"
   passwd "$1"
   while [ $? -ne 0 ]; do
      passwd "$1"
   done
   usermod -aG wheel "$1"
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

function installEssentials() {
   pacstrap /mnt linux linux-headers linux-firmware base networkmanager grub wpa_supplicant base base-devel
}

function generateFstab() {
   genfstab -U /mnt >> /mnt/etc/fstab
}

function setTimeZone() {
   sudo ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
}

function setUpLanguage() {
   echo  "LANG=en_US.UTF-8" > /etc/locale.conf
}

function setUpInitramfs() {
   mkinitcpio -P
}

function enterArchChroot() {
   arch-chroot /mnt
}

function installPackman() {
    # Check if pacman.conf exists
    if [ ! -e /mnt/etc/pacman.conf ]; then
        # Create pacman.conf file if it doesn't exist
        cp -f /etc/pacman.conf /mnt/etc/pacman.conf
    fi

    # Modify pacman.conf to specify the desired mirrorlist
    sed -i "s/^Server = .*$/Server = https://archlinux.es/\$repo/os/$arch/\$pkg.tar.xz\nServer = https://archlinux.es/\$repo/community/$arch/\$pkg.tar.xz\nServer = https://archlinux.es/\$repo/extra/$arch/\$pkg.tar.xz/" /mnt/etc/pacman.conf
}

function updateDependences() {
   pacman -Sy
   pacman -S efibootmgr
}

function main() {
   setUpKeyboard
   updateDependences
   createAndMountPartitions

   installPackman
   installEssentials
   generateFstab
   
   enterArchChroot

   setUpInitramfs
   setUpGRUB
   setTimeZone
   setUpHostname
   setUpLanguage
   setUpKeyboardLayout
   installAndSetUpSudo
   setUpRoot
   setUpUsers
}

main
