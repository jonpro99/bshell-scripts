#!/bin/sh

# quietly add a user without password
adduser -G state,wheel $1

# set password
echo "$1:$2" | chpasswd

