read -p 'set up the partitions, mount root to /mnt and press a key'
(echo 'Server = http://mirror.rit.edu/archlinux/$repo/os/$arch' && cat /etc/pacman.d/mirrorlist) > /etc/pacman.d/mirrorlist
pacstrap /mnt base{,-devel} git grub btrfs-progs
genfstab /mnt > /mnt/etc/fstab

arch-chroot /mnt /bin/bash -c 'grub-install --recheck /dev/sda'
arch-chroot /mnt /bin/bash -c 'mkinitcpio -p linux'
arch-chroot /mnt /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
