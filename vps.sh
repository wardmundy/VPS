#!/bin/bash
#set -e

if [ -d "/etc/selinux" ]; then
#Disable Selinux Temporarily if installed
setenforce 0

#Disable SeLinux Permanently if installed
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
fi

#Clean Yum Cache
yum clean all
rm -rf /var/cache/yum

#Download the beta repo of VitalPBX
wget -P /etc/yum.repos.d/ https://raw.githubusercontent.com/VitalPBX/VPS/master/resources/vitalpbx.repo

#Install SSH Welcome Banner
wget -P /etc/profile.d/ https://raw.githubusercontent.com/VitalPBX/VPS/master/resources/vitalwelcome.sh
chmod 644 /etc/profile.d/vitalwelcome.sh

#Intall other required dependencies
yum -y install epel-release php-5.4.16-42.el7

# Update the system & Clean Cache Again
yum clean all
rm -rf /var/cache/yum
yum -y update

# Install VitalPBX pre-requisites
wget https://raw.githubusercontent.com/VitalPBX/VPS/master/resources/pack_list
yum -y install $(cat pack_list)

# Install VitalPBX
mkdir -p /etc/ombutel
mkdir -p /etc/asterisk/ombutel
yum -y install vitalpbx vitalpbx-asterisk-configs vitalpbx-fail2ban-config vitalpbx-sounds vitalpbx-themes dahdi-linux dahdi-tools dahdi-tools-doc kmod-dahdi-linux fxload

# Speed up the localhost name resolving
sed -i 's/^hosts.*$/hosts:      myhostname files dns/' /etc/nsswitch.conf

cat << EOF >> /etc/sysctl.d/10-ombutel.conf
# Reboot machine automatically after 20 seconds if it kernel panics
kernel.panic = 20
EOF

# Set permissions
chown -R apache:root /etc/asterisk/ombutel

# Restart httpd
systemctl restart httpd

#Start ombutel-dbsetup
systemctl start ombutel-dbsetup.service

# Enable the http access:
firewall-cmd --add-service=http
firewall-cmd --reload
