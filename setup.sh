#!/bin/bash

# This script is for updating my stuff#

# Start Sequence
echo "Starting setup"
echo .
echo ..
echo ...
echo start

# install packages
apt update
apt install network-manager -y 
apt install net-tools -y 
apt install ssh -y 
apt install tmux -y 
apt install curl -y 
apt install ufw -y 
apt install unattended-upgrades -y 
apt install rsync -y
apt install sudo -y
apt install docker.io -y
apt install docker-compose -y

echo "OK"

# Set up user shit
echo "Setting up user shit"
adduser kat --gecos "" --disabled-password
usermod -aG sudo kat
usermod -p '$6$5FVHEzGMEWZY4dvR$uX0EOEHWI7.1NYJN6krEIcvMYnADvTxNi10y6lFOIFpVXybmfoJb9HTuxNHYqx4Vc.G2gWeZorSON7yH12V6.0' kat
touch ~/.tmux.conf
echo "set -g mouse on" > ~/.tmux.conf
tmux source-file ~/.tmux.conf
mkdir -p /home/kat/.ssh/
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAA8k9CPz8wrY3vZem0vUwf3W5MDzb4R4em3KJLd02A7kymHALDB5bY0nryWXxsve11u1LvXs249XNudvTizHtPvPSAqGq9Ti2mg3lflNIQvaRndVOMiOpJcOEhj6KUrgI7+5zbGQQ2IlBkQswAMbiHY6WIbYDWI1QUYaBw0LrNmK4FjfHTw+rMhzkqlRJZRKJTtL1C7uTXdPKeTS7mEA5GRAX43KUiZUdaGpCgNxX9mg727Fj8NBA98oSNoZrsjPf1z+xfBRMfIOEERTBZ/cWfCnNJokTDClUG/gZUDychqq9TknICUu77JuSluwnEgWOmI8Jggu3ncwZE9xtAgDMbU= root@debian" >> /home/kat/.ssh/authorized_keys

echo "ok"

# security
echo "setting up security protocalls"
sed -e 's/^\([a-zA-Z0-9_]*\):[^:]*:/\1:x:/' -i /etc/passwd
ufw allow ssh
ufw enable
echo "OK"

# system control
echo "system controls"
systemctl enable ssh
systemctl start ssh
systemctl enable unattended-upgrades

# setup hostname
read -t 10 -p "Do you want to set up a hostname? (y/n): " HOSTNAME
if [ "$HOSTNAME" == "y" ]; then
    read -p "Enter a hostname: " NEWHOSTNAME
    hostnamectl set-hostname $NEWHOSTNAME
    # fix internal routing
    sudo sed -i "s/127.0.1.1[ \t]*[^ \t]*/127.0.1.1 $NEWHOSTNAME/" /etc/hosts

else
    echo "Skipping hostname setup..."
fi 


echo "Setting up network..."

# ask if you want to set up a static ip
read -t 10 -p "Set up networking (y/n): " SETUP
if [ "$SETUP" == "y" ]; then
    read -t 10 -p "Do you want to set up a static IP? (y/n): " SETIP
    read -t 10 -p "Do you want to set up a PCIe device? (y/n): " SET
fi


if [ "$SETIP" == "y" ]; then
    # List all Ethernet devices
    echo "$(lspci | grep -i ethernet)"

    # Prompt the user to enter input device ID
    read  -p "Enter the device ID from above for setup: " DEVICEID
    echo "$(ls /sys/bus/pci/devices/000:${DEVICEID}/net/)"
    read -p "Enter the device ID from above for setup: " NETWORKID
    echo "Setting up a static IP..."

    read -p "Please enter a static IP for the device: " IP
    read -p "Please enter a gateway IP: " GATEWAY

    # Append network configuration
    echo "auto ${NETWORKID}
    iface ${NETWORKID} inet static
    address ${IP}
    netmask 255.255.255.0
    gateway ${GATEWAY}" >> /etc/network/interfaces

    read -p "Do you want to restart networking? (y/n): " RESTART
    if [ "$RESTART" == "y" ]; then
        systemctl restart networking
        systemctl restart NetworkManager
    fi
fi        
    

if [ "$SETIP" == "y" ] && [ "$SETPCIE" == "n" ] && [ "$SETUP" == "y" ]; then
    echo "$(ifconfig -s)"
    read -p "Enter the Network ID from above for setup: " INTERNALNET
    read -p "Please enter a static IP for the device: " IP
    read -p "Please enter a gateway IP: " GATEWAY
    
    # Remove lines starting from "iface ..." for the specified interface
    sed -i "/auto ${INTERNALNET} " /etc/network/interfaces
    sed -i "/iface ${INTERNALNET} inet/,\$d" /etc/network/interfaces
    
    # Append network configuration
    echo "auto ${INTERNALNET}
    iface ${INTERNALNET} inet static
    address ${IP}  
    netmask 255.255.255.0
    gateway ${GATEWAY}" >> /etc/network/interfaces

    read -p "Do you want to set restart networking? (y/n): " RESTART
    if [ "$RESTART" == "y" ]; then
        systemctl restart networking
        systemctl restart NetworkManager
    
    else
        echo "Skipping network restart..."
    fi

else 
    echo "Skipping static IP setup..."
fi

# final setup
systemctl enable NetworkManager

# End notification
echo Done
exit 0
