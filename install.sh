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

   mkfs.vfat -F32 "${disk}1" 
}

function mountPartitions() {

   # Assuming /dev/sdx1 is the ESP, /dev/sdx2 is the swap, and /dev/sdx3 is the root ("/") partition
   disk=$device
   # Create mount points
   mkdir -p "/mnt"

   # Mount the partitions
   mount "${disk}3" "/mnt"        # Mount root ("/") to /mnt

   mkswap /dev/sda2
   swapon
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

function installEssentials() {
   pacstrap /mnt linux linux-headers linux-firmware base networkmanager grub wpa_supplicant base base-devel
}

function enterArchChroot() {
   arch-chroot "/mnt" "/bin/bash" -c "./$1"
}

function installPackman() {
    # Check if pacman.conf exists
    if [ ! -e "/mnt/etc/pacman.conf" ]; then
        # Create pacman.conf file if it doesn't exist
        cp -f "/etc/pacman.conf" "/mnt/etc/pacman.conf"
    fi

    # Modify pacman.conf to specify the desired mirrorlist
    sed -i "s/^Server = .*$/Server = https://archlinux.es/\$repo/os/$arch/\$pkg.tar.xz\nServer = https://archlinux.es/\$repo/community/$arch/\$pkg.tar.xz\nServer = https://archlinux.es/\$repo/extra/$arch/\$pkg.tar.xz/" "/mnt/etc/pacman.conf"
}

function updateDependences() {
   pacman -Sy
   InstallPackage "efibootmgr"
}

function setUpArchChrootEnv() {
   cp "$1" /mnt
}

function generateFstab() {
   mkdir -p "/mnt/etc"
   genfstab -U "/mnt" >> "/mnt/etc/fstab"
}

function main() {
   setUpKeyboard
   updateDependences
   createAndMountPartitions
   generateFstab

   installPackman
   installEssentials

   configfile="config.sh"
   
   setUpArchChrootEnv "$configfile"

   enterArchChroot "$configfile $device"

   umount -a # In order to do not corrupt any file      

   # reboot
}
main
