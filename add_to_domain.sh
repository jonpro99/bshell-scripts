#!/bin/bash
echo '==================================================='
echo ' Adding to AD server'
echo '==================================================='

##Define Vars::
HOSTNAME=`hostname`
DOMAINNAME="TRENDSHIFT.INT"
DOMAINUSER="jprough"
DOMAINPASS="Ohsohot3!"
###############################
##For a interactive install####
###############################
# echo -n "Enter your the Hostname you wish to connect to and press [ENTER]: "
# read HOSTNAME
# echo -n "Enter your the domain you wish to connect to and press [ENTER]: "
# read DOMAINNAME
# echo -n "Enter your AD User name and press [ENTER]: "
# read DOMAINUSER
# echo -n "Enter your AD User Password and press [ENTER]: "
# read DOMAINPASS
################
##Install PBIS##
################
yum clean all
yum install pbis-open -y
yum install bind-utils nmap yum-utils -y
################
##Lets Do This##
################
domainjoin-cli leave
domainjoin-cli join $DOMAINNAME $DOMAINUSER $DOMAINPASS
/opt/pbis/bin/config RequireMembershipOf "$DOMAINNAME\\linuxadmins"
/opt/pbis/bin/config UserDomainPrefix $DOMAINNAME
/opt/pbis/bin/config HomeDirTemplate %H/%U
/opt/pbis/bin/config LoginShellTemplate /bin/bash
/opt/pbis/bin/config AssumeDefaultDomain true
/opt/pbis/bin/ad-cache --delete-all
/opt/pbis/bin/ad-cache --delete-all --force-offline-delete true
/opt/pbis/bin/update-dns
#################################################
##Mom is the word of god in the hart of a child##
#################################################
echo "%${DOMAINNAME%????}\\linuxadmins ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "%${DOMAINNAME%????}\\Domain^Admins ALL=(ALL:ALL) ALL" >> /etc/sudoers


##This is the End##
echo -n "END OF LINE"

