#!/bin/bash
for f in `cat servers.txt`; do echo "### $f ###"; rsync --rsync-path="sudo rsync" "ssh -i 1020750-private.pem" $1 1020750@$f:$2 ; done
