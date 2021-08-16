#!/bin/bash

servers=`cat servers.txt`
for f in $servers; do echo "### $f ###"; scp -r -i Nonprod.pem "$1" root@$f:"$2"; done

