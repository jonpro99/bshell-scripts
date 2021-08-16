echo '==================================================='
echo ' Adding to AD server'
echo '==================================================='
yum clean all
                rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
                rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
echo '==================================================='
echo ' Installing Dependencies'
echo '==================================================='
yum install bind-utils nmap yum-utils -y
yum install yum-plugin-replace
yum install pbis-open -y
echo '===================================q================'
echo ' Validating DNS and access to Active Directory'
echo '==================================================='
echo -n "Enter your the domain you wish to connect to and press [ENTER]: "
read DOMAINNAME
ns=$(cat /etc/resolv.conf  | grep -v '^#' | grep nameserver | awk '{print $2}')
for i in $ns; do ptr=$(host $i | sed 's/Name: //' | sed 's/ .*//g' | head -n 1)
  if dig @$i -t ns $DOMAINNAME |grep -qai '$DOMAINNAME'; then 
    echo $i $ptr OK; 
  else 
    echo $i $ptr failed; 
fi; 
done

dig $DOMAINNAME ANY
echo '==================================================='
echo ' Gathering needed permissions'
echo '==================================================='
echo -n "Enter your the Host name you wish to connect to and press [ENTER]: "
read HOSTNAME

echo -n "Enter your AD User name and press [ENTER]: "
read DOMAINUSER
echo -n "Enter your AD User Password and press [ENTER]: "
read DOMAINPASS

domainjoin-cli leave
domainjoin-cli join $DOMAINNAME $DOMAINUSER $DOMAINPASS
/opt/pbis/bin/config RequireMembershipOf "$DOMAINNAME\\Domain^Admins" "$DOMAINNAME\\linuxadmins"
/opt/pbis/bin/config UserDomainPrefix $DOMAINNAME
/opt/pbis/bin/config HomeDirTemplate %H/%U
/opt/pbis/bin/config LoginShellTemplate /bin/bash
/opt/pbis/bin/config AssumeDefaultDomain true
echo "%${DOMAINNAME%????}\\linuxadmins ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "%${DOMAINNAME%????}\\Domain^Admins ALL=(ALL:ALL) ALL" >> /etc/sudoers
/opt/pbis/bin/update-dns