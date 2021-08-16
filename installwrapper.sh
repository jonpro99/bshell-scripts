#!/bin/bash
# installwrapper.sh & user-data-hardening.sh
# Base install configurations and security 
# Created due to lack of Orcistration tools like Ansible or Puppet(I hate Puppet)
# Authors: Joanthan Prough B&D NA
# Date: 07/12/2014
# Created for the Arizona Migration Project on JAVA JABOSS deployment
# Script intended to be supplied as userdata to a cloud of some flavor.
# Enables some sane sysctl defaults, turns up iptables, and
# Yes there is a llot of junk here
# installs a HIDS / NITS package
# you can set the host-name as the first pram, or let the script grab it via CLi
# this is not in order, Some items like network need to be first rather than last as you can clearly undetstand(you cannot run a 1/4 mile before you put the tires on)

#  LEts get started shall we, I have a odd sense of silly in me, please forgive my fucntion names. 


HOSTNAME=$1
DOMAINNAME=$2
if ! [ $HOSTNAME ] ; then echo "Need Hostname and domainname - like this - ./installwrapper.sh HOSTNAME DOMAINNAME.INT" exit @ ; fi
SERVER=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)" --query 'Tags[*].Value' --output text)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

if [ $(id -u) != 0 ]; then
	echo "You're not root, I don't know you!! Go Away!!"
	exit 0
 fi
# Set some Var's
GROUP_NAME="xxx"
USER_NAME="xxx"
USER_PASSWORD="xxx"
SOFTWARE_DIRECTORY="/tmp"
BASE_DIR="/opt/xxx"
JBOSS_HOME="${BASE_DIR}"
#Dont go crazy now
MEMORY_TO_RESERVE_IN_GIGA_BYTES="2"
NUMBER_OF_OPEN_FILE_DESCRIPTORS="8192"
JVM_FILE_NAME="jdk-6u34-linux-x64.tar.gz"
# Only set JAVA_HOME when Oracle JDK is used
JAVA_HOME="${BASE_DIR}/jvm/jdk1.6.0_34"
# Supply your email here
email_address="jonathan@prough.us"

# Other things worth verifying / changing:
IPTABLES=/sbin/iptables
IP6TABLES=/sbin/ip6tables
MODPROBE=/sbin/modprobe

admommy() {
echo '==================================================='
echo ' Adding to AD server'
echo '==================================================='
echo -n "Enter your AD User name and press [ENTER]: "
read uname
echo "search devaz.int" > /etc/resolv.conf
echo "nameserver 10.135.135.12" >> /etc/resolv.conf
domainjoin-cli leave
domainjoin-cli join $DOMAINNAME $uname
/opt/pbis/bin/config UserDomainPrefix DOMAIN
/opt/pbis/bin/config HomeDirTemplate %H/%U
/opt/pbis/bin/config LoginShellTemplate /bin/bash
/opt/pbis/bin/config AssumeDefaultDomain true
/opt/pbis/bin/config RequireMembershipOf "$DOMAINNAME\\Domain^Admins" "$DOMAINNAME\\ptladmins"
echo "%${DOMAINNAME%????}\\ptladmins ALL=(ALL:ALL) ALL" >> /etc/sudoers
}

interstuff() {
echo '==================================================='
echo ' Setting Netowrk Info'
echo '==================================================='
INT_INTF=eth0
#EXT_INTF=eth1
INT_NET=$(ifconfig $INT_INTF | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
#EXT_NET=$(ifconfig $EXT_INTF | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
#sed -i "s/^\(HOSTNAME\s*=\s*\).*$/\1$SERVER/" /etc/sysconfig/network
#echo "$PRIVATE_IP $SERVER" >> /etc/hosts
}

# Firewall
# Modified from http://www.cipherdyne.org/LinuxFirewalls/ch01/
firewall() {
echo '==================================================='
echo ' Firewal'
echo '==================================================='
### flush existing rules and set chain policy setting to DROP
echo "[+] Flushing existing iptables rules..."
$IPTABLES -F
$IPTABLES -F -t nat
$IPTABLES -X
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP

### this policy does not handle IPv6 traffic except to drop it.
#
echo "[+] Disabling IPv6 traffic..."
$IP6TABLES -P INPUT DROP
$IP6TABLES -P OUTPUT DROP
$IP6TABLES -P FORWARD DROP
}


go_out_get_milk() {
echo '==================================================='
echo ' Get some stuff and junk'
echo '==================================================='
curl http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > ~/.ssh/authorized_keys
wget 10.135.135.28/JMP/pbis-open-8.2.2.2993.linux.x86_64.rpm.sh -O /tmp/pbis-open-8.2.2.2993.linux.x86_64.rpm.sh
wget 10.135.135.28/JMP//te_agent.bin -O /tmp/te_agent.bin
wget 10.135.135.28/JMP/hardening-script-1.0-el6.noarch.rpm -O /tmp/hardening-script-1.0-el6.noarch.rpm
wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
}

clean_me() {
echo '==================================================='
echo ' This House is is a mess'
echo '==================================================='
echo "" > ~/.ssh/known_hosts
echo "" > /etc/environment
echo  'export PS1="\[\033[38;5;21m\][\[$(tput sgr0)\]\[\033[38;5;196m\]\u\[$(tput sgr0)\]\[\033[38;5;147m\]@\[$(tput sgr0)\]\[\033[38;5;208m\]\H\[$(tput sgr0)\]\[\033[38;5;21m\]]\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;112m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;160m\]\\$ \[$(tput sgr0)\] "' >> /etc/bashrc
}

i_have_friends() {
echo '==================================================='
echo ' Set the network params'
echo '==================================================='
echo " Networking EC2 Style"
echo  'NETWORKING=yes' > /etc/sysconfig/network
echo  'NETWORKING_IPV6=no' >> /etc/sysconfig/network
echo  'HOSTNAME=$HOSTNAME' >> /etc/sysconfig/network
echo  'DOMAINNAME=$DOMAINNAME' >> /etc/sysconfig/network
echo  "supersede  domain-name "$DOMAINNAME";" > /etc/dhcp/dhclient.conf
echo  "supersede  search "$DOMAINNAME";" >> /etc/dhcp/dhclient.conf
echo 'timeout 30;' >> /etc/dhcp/dhclient.conf
echo 'retry 300;' >> /etc/dhcp/dhclient.conf
echo  'DEVICE=eth0' > /etc/sysconfig/network-scripts/ifcfg-eth0
echo  'BOOTPROTO=dhcp' >>/etc/sysconfig/network-scripts/ifcfg-eth0
echo  'ONBOOT=on' >>/etc/sysconfig/network-scripts/ifcfg-eth0
echo  'DHCP_HOSTNAME=$HOSTNAME' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep $HOSTNAME /etc/hosts 2>/dev/null; [ $? -eq 0 ] && echo"Hostname found in hosts file" || echo "Host-name not found in hosts file adding*this is not correct DNS should be used*" && sudo echo "127.0.0.1    localhost locahost.localdomain $HOSTNAME" > /etc/hosts
}

yum_yum() {
	echo '==================================================='
	echo ' YUM YUM'
	echo '==================================================='
		mv /etc/yum.repos.d/CentOS-* /etc/
		rm /etc/yum.repos.d/*.repo
		mv /etc/CentOS-* /etc/yum.repos.d/
		rm -f /var/lib/rpm/__db*
		rpm --rebuilddb
	yum clean all
		rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
		rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
	yum install pbis-open
# AWS/Python/PIP
	yum install -y python python-pip
	pip install awscli
# NIDS - psad / Log Reporting / HIDS - Aide
	yum install -y logwatch openswan scrub vlock postfix fail2ban psad aide
	aideinit
	aide -u
	yum update -y
}

hello_security() {
echo '==================================================='
echo ' Login Banner'
echo '==================================================='
login_banner_text="You[\s\n]+are[\s\n]+accessing[\s\n]+a[\s\n]+U.S.[\s\n]+Government[\s\n]+\(USG\)[\s\n]+Information[\s\n]+System[\s\n]+\(IS\)[\s\n]+that[\s\n]+is[\s\n]+provided[\s\n]+for[\s\n]+USG-authorized[\s\n]+use[\s\n]+only.[\s\n]*By[\s\n]+using[\s\n]+this[\s\n]+IS[\s\n]+\(which[\s\n]+includes[\s\n]+any[\s\n]+device[\s\n]+attached[\s\n]+to[\s\n]+this[\s\n]+IS\),[\s\n]+you[\s\n]+consent[\s\n]+to[\s\n]+the[\s\n]+following[\s\n]+conditions\:[\s\n]*-[\s\n]*The[\s\n]+USG[\s\n]+routinely[\s\n]+intercepts[\s\n]+and[\s\n]+monitors[\s\n]+communications[\s\n]+on[\s\n]+this[\s\n]+IS[\s\n]+for[\s\n]+purposes[\s\n]+including,[\s\n]+but[\s\n]+not[\s\n]+limited[\s\n]+to,[\s\n]+penetration[\s\n]+testing,[\s\n]+COMSEC[\s\n]+monitoring,[\s\n]+network[\s\n]+operations[\s\n]+and[\s\n]+defense,[\s\n]+personnel[\s\n]+misconduct[\s\n]+\(PM\),[\s\n]+law[\s\n]+enforcement[\s\n]+\(LE\),[\s\n]+and[\s\n]+counterintelligence[\s\n]+\(CI\)[\s\n]+investigations.[\s\n]*-[\s\n]*At[\s\n]+any[\s\n]+time,[\s\n]+the[\s\n]+USG[\s\n]+may[\s\n]+inspect[\s\n]+and[\s\n]+seize[\s\n]+data[\s\n]+stored[\s\n]+on[\s\n]+this[\s\n]+IS.[\s\n]*-[\s\n]*Communications[\s\n]+using,[\s\n]+or[\s\n]+data[\s\n]+stored[\s\n]+on,[\s\n]+this[\s\n]+IS[\s\n]+are[\s\n]+not[\s\n]+private,[\s\n]+are[\s\n]+subject[\s\n]+to[\s\n]+routine[\s\n]+monitoring,[\s\n]+interception,[\s\n]+and[\s\n]+search,[\s\n]+and[\s\n]+may[\s\n]+be[\s\n]+disclosed[\s\n]+or[\s\n]+used[\s\n]+for[\s\n]+any[\s\n]+USG-authorized[\s\n]+purpose.[\s\n]*-[\s\n]*This[\s\n]+IS[\s\n]+includes[\s\n]+security[\s\n]+measures[\s\n]+\(e.g.,[\s\n]+authentication[\s\n]+and[\s\n]+access[\s\n]+controls\)[\s\n]+to[\s\n]+protect[\s\n]+USG[\s\n]+interests[\s\n]+--[\s\n]+not[\s\n]+for[\s\n]+your[\s\n]+personal[\s\n]+benefit[\s\n]+or[\s\n]+privacy.[\s\n]*-[\s\n]*Notwithstanding[\s\n]+the[\s\n]+above,[\s\n]+using[\s\n]+this[\s\n]+IS[\s\n]+does[\s\n]+not[\s\n]+constitute[\s\n]+consent[\s\n]+to[\s\n]+PM,[\s\n]+LE[\s\n]+or[\s\n]+CI[\s\n]+investigative[\s\n]+searching[\s\n]+or[\s\n]+monitoring[\s\n]+of[\s\n]+the[\s\n]+content[\s\n]+of[\s\n]+privileged[\s\n]+communications,[\s\n]+or[\s\n]+work[\s\n]+product,[\s\n]+related[\s\n]+to[\s\n]+personal[\s\n]+representation[\s\n]+or[\s\n]+services[\s\n]+by[\s\n]+attorneys,[\s\n]+psychotherapists,[\s\n]+or[\s\n]+clergy,[\s\n]+and[\s\n]+their[\s\n]+assistants.[\s\n]+Such[\s\n]+communications[\s\n]+and[\s\n]+work[\s\n]+product[\s\n]+are[\s\n]+private[\s\n]+and[\s\n]+confidential.[\s\n]+See[\s\n]+User[\s\n]+Agreement[\s\n]+for[\s\n]+details."
cat <<EOF >/etc/issue
$login_banner_text
EOF
}

trip_of_the_brain() {
echo '==================================================='
echo ' INstall Tripwire'
echo '==================================================='
/usr/local/tripwire/te/agent/bin/uninstall.sh 
/tmp/te_agent.bin --eula accept --silent --server-host 10.251.19.242 --server-port 9898 --passphrase f835nWpK --rtmport 1169; echo "java.rmi.server.hostname=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`" >> /usr/local/tripwire/te/agent/data/config/agent.properties; echo "tw.rpc.interfaceAddr=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`" >> /usr/local/tripwire/te/agent/data/config/agent.properties
}

create_group_and_user() {
echo '==================================================='
echo ' Create local group and or user'
echo '==================================================='
    echo "CREATING GROUP ${GROUP_NAME}, AND USER ${USER_NAME}"
    groupadd ${GROUP_NAME}; echo ${USER_PASSWORD} | passwd --stdin ${USER_NAME}
}
 
remove_group_and_user() {
echo '==================================================='
echo ' Remove groupt and or user'
echo '==================================================='
    userdel -rf ${USER_NAME}; groupdel ${GROUP_NAME}
}
 
change_bash_profile() {
echo '==================================================='
echo ' Bash is a mess'
echo '==================================================='
    USER_HOME_DIR="/home/${USER_NAME}"
    echo "CREATING BASH PROFILE"
    echo '# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
# User specific environment and startup programs
JBOSS_HOME="${JBOSS_HOME}"
export JBOSS_HOME
JAVA_HOME="${JAVA_HOME}"
export JAVA_HOME
PATH=$JAVA_HOME/bin:$JBOSS_HOME/bin:$PATH:$HOME/bin
export PATH' > ${USER_HOME_DIR}/.bash_profile
}

edit_os_settings() {
	echo '==================================================='
	echo ' set config OS'
	echo '==================================================='
    	NUMBER_OF_HUGE_PAGES=$[ (${MEMORY_TO_RESERVE_IN_GIGA_BYTES} * 1024**3) / (2 * 1024**2) ]
    	MEM_LOCK=$[ ${NUMBER_OF_HUGE_PAGES} * 2048 ]
	echo "EDITING /etc/sysctl.conf"
    cat<< EOF >> /etc/sysctl.conf
# increase TCP max buffer size (depending on the type of NIC and the round-trip time these values can be changed)
# Maximum TCP Receive Window
net.core.rmem_max = 8388608
net.core.rmem_default = 8388608
# Maximum TCP Send Window
net.core.wmem_max = 8388608
net.core.wmem_default = 8388608
#  memory reserved for TCP receive buffers (vector of 3 integers: [min, default, max])
net.ipv4.tcp_rmem = 4096 87380 8388608
# memory reserved for TCP send buffers (vector of 3 integers: [min, default, max])
net.ipv4.tcp_wmem = 4096 87380 8388608
 
# increase the length of the processor input queue
net.core.netdev_max_backlog = 30000
# maximum amount of memory buffers (could be set equal to net.core.rmem_max and net.core.wmem_max)
net.core.optmem_max = 20480
# socket of the listen backlog
net.core.somaxconn = 1024
 
# tcp selective acknowledgements (disable them on high-speed networks)
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
# Timestamps add 12 bytes to the TCP header
net.ipv4.tcp_timestamps = 1
# Support for large TCP Windows - Needs to be set to 1 if the Max TCP Window is over 65535
net.ipv4.tcp_window_scaling = 1
# The interval between the last data packet sent (simple ACKs are not considered data) and the first keepalive probe
net.ipv4.tcp_keepalive_time = 1800
# The interval between subsequential keepalive probes, regardless of what the connection has exchanged in the meantime
net.ipv4.tcp_keepalive_intvl = 30
# The number of unacknowledged probes to send before considering the connection dead and notifying the application layer
net.ipv4.tcp_keepalive_probes = 5
# The time that must elapse before TCP/IP can release a closed connection and reuse its resources.
net.ipv4.tcp_fin_timeout = 30
# Size of the backlog connections queue.
net.ipv4.tcp_max_syn_backlog = 4096
# The tcp_tw_reuse setting is particularly useful in environments where numerous short connections are open and left in TIME_WAIT state, such as web servers.
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
 
# The percentage of how aggressively memory pages are swapped to disk
vm.swappiness = 0
# The percentage of main memory the pdflush daemon should write data out to the disk.
vm.dirty_background_ratio = 25
# The percentage of main memory the actual disk writes will take place.
vm.dirty_ratio = 20
 
# set the number of huge pages based on the Hugepagesize, i.e., 2048kB
vm.nr_hugepages = ${NUMBER_OF_HUGE_PAGES}
 
# give permission to the group that runs the process to access the shared memory segment
# to this end open the /etc/group file and retrieve the group-id
vm.hugetlb_shm_group = ${GROUP_ID}
EOF
 
	echo "EDITING /etc/security/limits.conf"
	sed -i -e '/End of file/ i\\n# open file descriptors\n@'${GROUP_NAME}' soft nofile '${NUMBER_OF_OPEN_FILE_DESCRIPTORS}'\n@'${GROUP_NAME}' hard nofile '${NUMBER_OF_OPEN_FILE_DESCRIPTORS}'\n\n# memlock - maximum locked in-memory address space (kB), we set this equal to:\n# number_of_huge_pages * huge_page_size\n@'${GROUP_NAME}' soft memlock '${MEM_LOCK}'\n@'${GROUP_NAME}' hard memlock '${MEM_LOCK}'\n\n' etc/security/limits.conf
}


whats_up() {
echo '==================================================='
echo ' Way Cooler Banner'
echo '==================================================='
cat<<'EOF' >> /usr/local/bin/dynmotd
#!/bin/bash
PROCCOUNT=`ps -Afl | wc -l`
PROCCOUNT=`expr $PROCCOUNT - 5`
GROUPZ=`groups`
wget -q http://s3.amazonaws.com/ec2metadata/ec2-metadata -O ~/ec2-metadata && chmod 755 ~/ec2-metadata
if [[ $GROUPZ == *bandd* ]]; then
ENDSESSION=`cat /etc/security/limits.conf | grep "@wheel" | grep maxlogins | awk {'print $4'}`
PRIVLAGED="BandD User"
else
ENDSESSION="Unlimited"
PRIVLAGED="State User or Da\'root"
fi
black='\e[0;30m'        # Black
red='\e[0;31m'          # Red
green='\e[0;32m'        # Green
yellow='\e[0;33m'       # Yellow
blue='\e[0;34m'         # Blue
purp='\e[0;35m'       	# Purple
cyan='\e[0;36m'         # Cyan
ired='\e[0;91m'         # ired
white='\e[0;37m'        # White
RESET='tput sgr0'
SERVICE='run.sh'
IFS=$'\n'
echo -e "\e[0m"
echo -e "\n"
echo -e "$green


             _     _________   ___    _
            / \   |__  /  _ \ / _ \  / \
           / _ \    / /| | | | | | |/ _ \
          / ___ \  / /_| |_| | |_| / ___ \
         /_/   \_\/____|____/ \___/_/   \_\

$blue+++++++++++++: $white System Data $blue :+++++++++++++++
$blue+ $white Hostname $purp    = $white `hostname`
$blue+ $white Kernel $purp      = $white `uname -r`
$blue+ $white Uptime $purp      = $white `uptime | sed 's/.*up ([^,]*), .*/1/'`
$blue+ $white Memory $purp      = $white `cat /proc/meminfo | grep MemTotal | awk {'print $2'}` kB
$blue+++++++++++++: $white User Data $blue :+++++++++++++++
$blue+ $white Username $purp    = $green `whoami`
$blue+ $white Privlages $purp   = $green $PRIVLAGED
$blue+ $white Sessions $purp    = $green `who | grep $USER | wc -l` of $ENDSESSION MAX
$blue+ $white Processes $purp   = $green $PROCCOUNT of `ulimit -u` MAX
$blue+++++++++++++: $white AWS EC2 Information $blue :+++++++++++++++"
for a in `~/ec2-metadata --all`; do echo -e "$blue+ $green $a "; done
echo -e "$blue+++++++++++++: $purp  Security Information $blue :+++++++++++++++"
for i in $last; do echo -e "$blue+ $purp $i     "; done
echo -e "$blue+++++++++++++: $white Helpful Information $blue :+++++++++++++++"
if ps aux | grep -i 'run.sh -c' | grep -v grep  > /dev/null
then
echo -e "$white JBOSS IS $green RUNNING\n"
ps aux | grep -i 'run.sh -c' | grep -v grep
else
echo -e "$white JBOSS IS $red NOT RUNNING"
fi
echo -e "\e[0m"
EOF
	echo  "/usr/local/bin/dynmotd" >> /etc/bashrc
}

disable_selinux() {
	echo '==================================================='
	echo ' SELINUX you need it but no one knows it'
	echo '==================================================='
   	echo "DISABLING SELINUX in /etc/selinux/config"
    sed -i -e '/SELINUX=enforcing/ s:SELINUX=enforcing:SELINUX=disabled:g' /etc/selinux/config
}
 
disable_firewall() {
	echo '==================================================='
	echo ' What Wait'
	echo '==================================================='	
   	echo "DISABLING FIREWAL"
    service iptables stop
    chkconfig iptables off
    service iptables status
}
 
install_open_jdk() {
	echo '==================================================='
	echo ' Open For the win JDK'
	echo '==================================================='
	echo "INSTALLING OPENJDK"
		yum -y install java-1.7.0-openjdk-devel.x86_64
		yum -y install java-1.6.0-openjdk-devel.x86_64
	}
 
install_oracle_jdk() {
echo '==================================================='
echo ' Oracle has taken control'
echo '==================================================='
    if [ ! -d "${BASE_DIR}/jvm" ]; then
        su - ${USER_NAME} -c "mkdir -p ${BASE_DIR}/jvm"
    fi 
 
    echo "INSTALLING ORACLE JDK"
    su - ${USER_NAME} -c "tar xzf ${SOFTWARE_DIRECTORY}/${JVM_FILE_NAME} -C ${BASE_DIR}/jvm"
 
    echo 'ADJUST ENTROPY GATHERING DEVICE SETTINGS'
    su - ${USER_NAME} -c "sed -i -e '/securerandom/ s_file:/dev/urandom_file:/dev/./urandom_' ${JAVA_HOME}/jre/lib/security/java.security"
}

sec() {
cd /tmp/
rpm -ivh hardening-script-1.0-el6.noarch.rpm
}

# Do all this stuff and junk

go_out_get_milk
change_bash_profile
clean_me
i_have_friends
yum_yum
hello_security
edit_os_settings
whats_up
create_group_and_user
admommy
disable_selinux
disable_firewall
