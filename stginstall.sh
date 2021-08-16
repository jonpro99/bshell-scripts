#!/bin/bash
hostname=$1
domainname=$2
curl http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > ~/.ssh/authorized_keys
hostname $hostname
echo  'NETWORKING=yes' > /etc/sysconfig/network
echo  'NETWORKING_IPV6=no' >> /etc/sysconfig/network
echo  'HOSTNAME=$hostname' >> /etc/sysconfig/network
echo  'DOMAINNAME=$domainname' >> /etc/sysconfig/network
echo "" > ~/.ssh/known_hosts
echo  'supersede  domain-name "$domainname" ;' > /etc/dhcp/dhclient.conf
echo 'timeout 30;' >> /etc/dhcp/dhclient.conf
echo 'retry 300;' >> /etc/dhcp/dhclient.conf
echo  'DEVICE=eth0' > /etc/sysconfig/network-scripts/ifcfg-eth0
echo  'BOOTPROTO=dhcp' >>/etc/sysconfig/network-scripts/ifcfg-eth0
echo  'ONBOOT=on' >>/etc/sysconfig/network-scripts/ifcfg-eth0
echo  'DHCP_HOSTNAME=$hostname' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "" > /etc/environment
wget 169.254.169.254/jmp/dynmotd -O /usr/local/bin/dynmotd
chmod 755  /usr/local/bin/dynmotd
echo  'export PS1="\[\033[38;5;21m\][\[$(tput sgr0)\]\[\033[38;5;196m\]\u\[$(tput sgr0)\]\[\033[38;5;147m\]@\[$(tput sgr0)\]\[\033[38;5;208m\]\H\[$(tput sgr0)\]\[\033[38;5;21m\]]\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;112m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;160m\]\\$\[$(tput sgr0)\]"' >> /etc/bashrc
wget 10.135.135.28/jmp/pbis-open-8.2.2.2993.linux.x86_64.rpm -O /tmp/pbis-open-8.2.2.2993.linux.x86_64.rpm
yum clean all 
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh http://dl.atrpms.net/all/atrpms-repo-6-7.el6.x86_64.rpm
yum update -y
