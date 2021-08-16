#!/bin/sh
 
BASE_DIR="/opt/jboss"
JBOSS_HOME="${BASE_DIR}/active"
 
# Only set JAVA_HOME when Oracle JDK is used
#JAVA_HOME="${BASE_DIR}/jvm/jdk1.6.0_34"
# The following two variables are used in case Oracle JDK is used
#SOFTWARE_DIRECTORY="/tmp"
#JVM_FILE_NAME="jdk-6u34-linux-x64.tar.gz"

GROUP_NAME="appuser"
GROUP_ID="510"
USER_NAME="jboss"
USER_PASSWORD="jbosseap6!"
 
MEMORY_TO_RESERVE_IN_GIGA_BYTES="2"
NUMBER_OF_OPEN_FILE_DESCRIPTORS="8192"
script_runner()	{
/usr/bin/id -g bandd 2>/dev/null; [ $? -eq 0 ] && echo "Group found" || echo "Group not found creating bandd group" && sudo groupadd bandd && sudo echo "%bandd  ALL=(ALL) NOPASSWD:ALL" >> bandd && sudo echo "Defaults:%bandd        !requiretty" >> bandd && sudo chmod 440 bandd && sudo mv bandd /etc/sudoers.d/ && sudo usermod -a -G bandd 1020750
}
create_group_and_user() {
    echo "CREATING GROUP ${GROUP_NAME}, AND USER ${USER_NAME}"
    groupadd ${GROUP_NAME} -g ${GROUP_ID}
    useradd -g ${GROUP_NAME} ${USER_NAME}
    echo ${USER_PASSWORD} | passwd --stdin ${USER_NAME}
}
 
remove_group_and_user() {
    userdel -rf ${USER_NAME}
    groupdel ${GROUP_NAME}
}
 
change_bash_profile() {
    USER_HOME_DIR="/opt/${USER_NAME}"
 
    echo "CREATING BASH PROFILE"
    echo '# .bash_profile
 
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
 
# User specific environment and startup programs
 
JBOSS_HOME="'${JBOSS_HOME}'"
export JBOSS_HOME
 
JAVA_HOME="'${JAVA_HOME}'"
export JAVA_HOME
 
PATH=$JAVA_HOME/bin:$JBOSS_HOME/bin:$PATH:$HOME/bin
export PATH' > ${USER_HOME_DIR}/.bash_profile
}
 
edit_os_settings() {
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
    sed -i -e '/End of file/ i\\n# open file descriptors\n@'${GROUP_NAME}' soft nofile '${NUMBER_OF_OPEN_FILE_DESCRIPTORS}'\n@'${GROUP_NAME}' hard nofile '${NUMBER_OF_OPEN_FILE_DESCRIPTORS}'\n\n# memlock - maximum locked in-memory address space (kB), we set this equal to:\n# number_of_huge_pages * huge_page_size\n@'${GROUP_NAME}' soft memlock '${MEM_LOCK}'\n@'${GROUP_NAME}' hard memlock '${MEM_LOCK}'\n\n' /etc/security/limits.conf
}
 
disable_selinux() {
    echo "DISABLING SELINUX in /etc/selinux/config"
    sed -i -e '/SELINUX=enforcing/ s:SELINUX=enforcing:SELINUX=disabled:g' /etc/selinux/config
}
 
disable_firewall() {
    echo "DISABLING FIREWAL"
    service iptables stop
    chkconfig iptables off
    service iptables status
}
 
install_open_jdk() {
    echo "INSTALLING OPENJDK"
    yum -y install java-1.6.0-openjdk.x86_64
	alternatives --install /usr/bin/java java /usr/lib/jvm/jre-1.6.0-openjdk.x86_64/bin/java 120
}
 
install_oracle_jdk() {
    if [ ! -d "${BASE_DIR}/jvm" ]; then
        su - ${USER_NAME} -c "mkdir -p ${BASE_DIR}/jvm"
		su - ${USER_NAME} -c "wget --no-cookies --header "Cookie: s_nr=1359635827494; s_cc=true; gpw_e24=http%3A%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavase%2Fdownloads%2Fjdk6downloads-1902814.html; s_sq=%5B%5BB%5D%5D; gpv_p24=no%20value" http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-linux-x64-rpm.bin --no-check-certificate -O ./jdk-6u45-linux-x64-rpm.bin"
		su - ${USER_NAME} -c "alternatives --install /usr/bin/java java /usr/java/jdk1.6.0_34/bin/java 120""
    fi 
 
    echo "INSTALLING ORACLE JDK"
    su - ${USER_NAME} -c "chmod +x ${SOFTWARE_DIRECTORY}/${JVM_FILE_NAME}"
	su - ${USER_NAME} -c ${SOFTWARE_DIRECTORY}/${JVM_FILE_NAME}" 
    echo 'ADJUST ENTROPY GATHERING DEVICE SETTINGS'
    su - ${USER_NAME} -c "sed -i -e '/securerandom/ s_file:/dev/urandom_file:/dev/./urandom_' ${JAVA_HOME}/jre/lib/security/java.security"
}
key=/home/1020750/1020750-private.pem
sync_jboss_folders()	{
su - ${USER_NAME} -c "rsync -avz --delete --exclude={"*.bak*","*.tar*","*.gz*","*.log*","/tmp/*","/run/*","/work/*","/media/*","/lost+found"} -e "ssh -i ${key}" 1020750@10.251.29.195:/opt/jboss/ /opt/jboss/"
}
sync_jboss_folders

install_open_jdk

create_group_and_user
 
change_bash_profile
 
edit_os_settings
 
disable_selinux
 
disable_firewall

