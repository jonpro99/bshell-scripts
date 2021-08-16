#!/bin/bash

		#===============================================================#
		#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
		#===============================================================#
		#- IMPLEMENTATION                                               #
		#-    Purpose:        Add To AD, DNS							#
		#-    version         do_join-to-ad-rhel 1.8                    #
		#-    author          Jonathan Prough							#
		#-    Contributors:  					       		    	    #
		#-    copyright       Copyright (c) SAS           			    #
		#-    license         GNU General Public License                #
		#-    script_id       ${SCRIPT_NAME}                            #
		#===============================================================#
		#o  DEBUG OPTION                                                #
		#    set -n  # Uncomment to check your syntax, without execution#
		#    set -x  # Uncomment to debug this shell script             #
		#===============================================================#
		#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
		#===============================================================#
		
			echo '==================================================='
			echo ' Add to AD server'
			echo '==================================================='
			echo 'CENTOS, RHEL, ORACLE Linux repo(yum) install'
	##Define Vars::
	#Set Groups that can SUDO to root.  Default groups are Domain^Admins and Host_UnixServers_Admins Please incert others in list. One perline pelase.
	SUROOT="
	ITHosting
	"
	#this can be manualy filled in, however if the hostaname is a mismatch issues will arise.
	HOSTNAME=`hostname`
	#Domain to join
	DOMAINNAME="VSP.SAS.COM"
	#a validation on the FQDN to short if DNS is the promiry controler for the systems.  If Netbios is used this will not return a string.
	DNSIP=`dig +short $DOMAINNAME`
	#Add Domian user with permissions to attach a server
	DOMAINUSER=""
	#Optional is running a loop.  Tif not the domain password is not given you will be prompted.
	DOMAINPASS=""

 ##For a interactive install::#####################################################
 # echo -n "Enter your the Hostname you wish to connect to and press [ENTER]: "   #
 # read HOSTNAME                                                                  #
 # echo -n "Enter your the domain you wish to connect to and press [ENTER]: "     #
 # read DOMAINNAME                                                                #
 # echo -n "Enter your AD User name and press [ENTER]: "                          # 
 # read DOMAINUSER                                                                #
 # echo -n "Enter your AD User Password and press [ENTER]: "                      #
 # read DOMAINPASS                                                                #
 #	 echo '==================================================='                   #
 #	 echo '==================================================='                   #
 #	 echo -e "HOSTNAME is :: "$HOSTNAME""                                         #
 # 	 echo -e "DOMAINNAME is :: "$DOMAINNAME""                                     #
 #	 echo -e "DNS IP is :: "$DNSIP""                                              #
 #	 echo '==================================================='                   #
 #	 echo '==================================================='                   #
 ##################################################################################

 #Set pre-rec's::resolve.conf if not already done By DHCP##########################
 #	echo "search $DOMAINNAME" >> /etc/resolv.conf                                 #
 #	echo "nameserver $DNSIP" >> /etc/resolv.conf                                  #
 ##################################################################################

 #Manual validaton if needed#######################################################
 #  read -r -p "This all look good?  Continue? [Y/n] " input    		 		  #
 #  case $input in                                                                #
 #    [yY][eE][sS]|[yY])                                                          #
 #                echo "Yes, Lets Do this yo!"``				 				  #
 ##################################################################################

 #install repo::RHEL Version 6 or 7################################################
 #	breakfix before Satelite#######################################################
 #	 wget http://jumpboxp01.VSP.SAS.COM/tools/pbis-open-8.5.4-334.x86_64.rpm      #
 #	 wget http://jumpboxp01.VSP.SAS.COM/tools/pbis-open-upgrade-8.5.4-334.x86_64.rpm
 ##################################################################################
	wget -O /tmp/lst_sudoers.txt http://172.20.73.111/tools/lst_sudoers.txt
	wget -O /etc/yum.repos.d/pbiso.repo http://172.20.73.111/tools/pbiso.repo
	yum clean all
	yum install bind-utils nmap yum-utils wget -y
	 ##Install PBIS::
	yum --disablerepo=* --enablerepo=PBISO install pbis-open -y
	 ##Lets Do This::Set the configurations::
		# If on domian already lets Leave
				domainjoin-cli leave
		# Join to domain NOTE: AD will place into default computer container
				domainjoin-cli join VSP.SAS.COM $DOMAINUSER $DOMAINPASS
		# Set some defaults we all like# membership of AD group that can log into the server
				/opt/pbis/bin/config RequireMembershipOf "VSP.SAS.COM\\Domain^Users"
		# Removes the need to prefix all user ID's with domainname#
				/opt/pbis/bin/config UserDomainPrefix VSP.SAS.COM
		# Sets teh default Home direcotry for all profiles created by login and GPO
				/opt/pbis/bin/config HomeDirTemplate %H/%U
		# Sets teh default user shell#
				/opt/pbis/bin/config LoginShellTemplate /bin/bash
		# Sets the default domainname accross all configs
				/opt/pbis/bin/config AssumeDefaultDomain true
		# Inserts some group's that can sudo ALL (or root) Default on all systems is SSG\\Host_UnixServers_Admins. List of users who can SU to ROOT
				cat /tmp/lst_sudoers.txt >> /etc/sudoers
				#for su in $SUROOT; do echo "%SSG\\Host_UnixServers_Admins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; done
		# Clears the cache after join
				/opt/pbis/bin/ad-cache --delete-all
		# ADDS this IP and Hostname to DNS server.  
				#Will be the FQDN, this will create the A record, and attache the PTR. 
				/opt/pbis/bin/update-dns
				#This is a Dynamic entry and can be added to crontab to maintian any changes to DNS
				echo "5 4 * * * /opt/pbis/bin/update-dns" | tee -a /var/spool/cron/root
		# SSH Security:: Disallow root login via ssh::not for primetime:: C-RHEL-06-000237_chk::NISTIR7966 
				# sed -i 's|PermitRootLogin yes|PermitRootLogin no|' /etc/ssh/sshd_config
		# Disable empty passwords::Respect my athoraty::
				# sed -i 's|PermitEmptyPasswords yes|PermitEmptyPasswords no|' /etc/ssh/sshd_config
		# Fix to allow ssh after PBiS-O domain join::In normal AD Bridge opertations ChallengeResponseAuthentication is yes for chalang the AD auth::
				sed -i 's|ChallengeResponseAuthentication yes|ChallengeResponseAuthentication no|' /etc/ssh/sshd_config	
		# This is the END, curtin closeing, it was fun, come back soon now ya-hear::
				echo -n "END OF LINE"/n/n"..."/n//n
		exit 0 
 #Manual Validation Continued form above#######################################
 #	exit 0								      								  #
 #		;;							    									  #
 #   [nN][oO]|[nN])                                                           #
 #       echo "No? Ah Man!"                                                   #
 #       exit 1                                                               #
 #       ;;                                                                   #
 #   *)                                                                       #
 #      echo "Invalid input...Dork!"                                          #
 #       exit 1                                                               #
 #       ;;                                                                   #
 #   esac                                                                     #
 ##############################################################################
