1///////////////////////////////////////
       VM AND Creation of the LFS

LFS iso Creation : qemu-img create -f qcow2 ./lfs.qcow2 -o preallocation=off 18G

Iso Ubuntu Download : curl -O https://mirror.tutosfaciles48.fr/ubuntu/24.04.2/ubuntu-24.04.2-desktop-amd64.iso

Qemu vm creation from iso : qemu-img create -f qcow2 ./ubuntu-disk.qcow2 -o preallocation=off 128G

Script Bash pour lancer la VM avec l'iso lfs en second disk:

qemu-system-x86_64 \
	-enable-kvm \
	-m 28G \
	-smp cores=16,threads=2,sockets=1 \
	-cpu host \
	-net nic,model=virtio \
	-net user \
	-device virtio-balloon \
	-vga virtio \
	-full-screen \
	-daemonize \
	-hda ubuntu-proud.qcow2 \
	-hdb lfs.qcow2

2///////////////////////////////////////
            Setup lfs.iso to ext4 and mount entry point 

Enter cfdisk of lfs : sudo cfdisk /dev/sdb

Partitionning :

GPT->

[   New  ] -> partition size: 512M -> [  Type  ] -> select `EFI System`
[   New  ] -> partition size: 1G -> [  Type  ] -> select `Linux filesystem`
[   New  ] -> partition size: 14.5G -> [  Type  ] -> select `Linux filesystem`
[   New  ] -> partition size: 2G -> [  Type  ] -> select `Linux swap`



Formating Partition :
sudo mkfs.vfat -F32 /dev/sdb1
sudo mkfs -v -t ext4 /dev/sdb2
sudo mkfs -v -t ext4 /dev/sdb3
sudo mkswap /dev/sdb4

sudo -i
export LFS=/mnt/lfs
umask 022
export LFS_TGT=$(uname -m)-lfs-linux-gnu

mkdir -pv $LFS
mount -v -t ext4 /dev/sdb3 $LFS/
mkdir -pv $LFS/boot
mount -v -t ext4 /dev/sdb2 $LFS/boot
mkdir -pv $LFS/boot/efi
mount -v -t vfat /dev/sdb1 -o codepage=437,iocharset=iso8859-1 $LFS/boot/efi
/sbin/swapon -v /dev/sdb4

///////////////////////////////////////////////////////////////////////////////////

mkdir -pv $LFS/sources
chmod -v a+wt $LFS/sources

///////////////////////////////////////////////

touch $LFS/sources/wget-list-systemd
cd $LFS/sources
chmod +x check-lfs-sources.sh
./check-lfs-sources.sh
pushd $LFS/sources
  md5sum -c md5sums
popd
chown root:root $LFS/sources/*

//////////////////////////////////////////////////

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

