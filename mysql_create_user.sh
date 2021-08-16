#!/bin/bash
USERNAME='fyu'
USERPW='PasswordFU##23'
mysql --login-path=jwadmin -h 10.44.212.50 -e "grant all privileges on *.* to '${USERNAME}'@'%' identified by '${USERPW}' with grant option;flush privileges;"
mysql --login-path=jwadmin -h 10.44.212.51 -e "grant all privileges on *.* to '${USERNAME}'@'%' identified by '${USERPW}' with grant option;flush privileges;"
mysql --login-path=jwadmin -h 10.44.212.52 -e "grant all privileges on *.* to '${USERNAME}'@'%' identified by '${USERPW}' with grant option;flush privileges;"
mysql --login-path=jwadmin -h 10.44.212.53 -e "grant all privileges on *.* to '${USERNAME}'@'%' identified by '${USERPW}' with grant option;flush privileges;"
mysql --login-path=jwadmin -h 10.44.212.54 -e "grant all privileges on *.* to '${USERNAME}'@'%' identified by '${USERPW}' with grant option;flush privileges;"
