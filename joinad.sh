#!/bin/bash
# Trendshift 2016
yum -y install authconfig krb5-workstation pam_krb5 samba-common oddjob-mkhomedir sudo ntp
authconfig --disablecache --enablewinbind --enablewinbindauth --smbsecurity=ads --smbworkgroup=TRENDSHIFT --smbrealm=TRENDSHIFT.LOCAL --enablewinbindusedefaultdomain --winbindtemplatehomedir=/home/TRENDSHIFT.LOCAL/%U --winbindtemplateshell=/bin/bash --enablekrb5 --krb5realm=TRENDSHIFT.LOCAL --enablekrb5kdcdns --enablekrb5realmdns --enablelocauthorize --enablemkhomedir --enablepamaccess --updateall
cd /etc
cp krb5.conf krb5.conf.bck
wget http://10.44.212.41/krb5.conf
ntpdate 10.44.210.10
service winbind restart
net ads join trendshift.local -U Administrator
net ads testjoin
cd /home
mkdir TRENDSHIFT.LOCAL
chmod 777 TRENDSHIFT.LOCAL
cd /etc/pam.d
cp system-auth system-auth.bck
wget http://10.44.212.41/system-auth
cd /
echo '%linuxusers ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
chkconfig oddjobd on
chkconfig winbind on
chkconfig messagebus on
service winbind restart
service oddjobd restart
service messagebus restart
