#!/bin/bash

# Execute this script to install VSH

echo "-----------------"
echo "This script will install vsh on this machine"
echo "It has to be executed on the server and clients"
echo "- Yanis TALEB & Martin FOMBONNE, RT1"
echo "-----------------"
echo; echo "Press any key to continue"
read


if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root"
  exit
fi


echo "This script will erase any existing VSH installation"
echo "Continue ? [Y/n]"
read rep
if ! [[ $rep = "Y" ]]; then
	echo "Exiting..."
	exit
fi

# Verifies that the script is opened from the same dir
if [[ $0 =~ "/" ]]; then
	echo "Do not open the script from another directory !"
	echo "If you are in the same directory, be sure to use 'bash setup.sh'"
	exit
fi

# Creating vsh user
passwd=$(cat /etc/passwd)
if [[ $passwd =~ "vsh" ]]; then
    echo "'vsh' user already exists, recreating it"
	echo "Press any key to continue or CTRL+C to stop"
	read
	userdel vsh
	rm -rf /home/vsh
fi

useradd vsh -m
echo "Enter a password for 'vsh' user"
passwd vsh
rm -rf /home/vsh/*

mkdir /home/vsh/archives /home/vsh/browse
setfacl -m u:vsh:rwx /home/vsh/archives
setfacl -m u:vsh:rwx /home/vsh/browse

# Copying script files
rm -rf /opt/vsh

mkdir /opt/vsh/
cp ./vsh* /opt/vsh/
cp ./vsh.sh /usr/bin/vsh
export PATH

# Only root can modify vsh
chmod a-rw /opt/vsh/
chmod a+rx /opt/vsh/
chmod a-rw /usr/bin/vsh
chmod a+rx /usr/bin/vsh

echo; echo; echo

# Installing SSHPass
exists=$( which sshpass 2>&1 )
if [[ $exists =~ "no sshpass in" ]]; then
	distro=$(cat /etc/issue)
	echo "Installing sshpass"; echo
	if [[ $distro =~ "Arch" ]]; then
		pacman -Sy sshpass
	fi
	else if [[ $distro =~ "Debian" ]] || [[ $distro =~ "Ubuntu" ]] || [[ $distro =~ "Mint" ]]; then
		exec "apt update -y && apt install -y sshpass"
	fi
fi

echo "---- Done ----"
echo ; echo ; echo
echo "Now, you have to :"
echo " + make sure that you have a SSH deamon and make it listen on the port you want"
echo " + enjoy your vsh server :)"
