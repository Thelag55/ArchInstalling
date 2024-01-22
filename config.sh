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
   #We'll let a .aui file in case we ever need to back up
   if [[ ! -f /etc/sudoers.aui ]]; then
      cp -v "/etc/sudoers" "/etc/sudoers.aui"
   fi
   ## Uncomment to allow members of group wheel to execute any command
   sed -i '/%wheel ALL=(ALL) ALL/s/^#//' "/etc/sudoers"
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

