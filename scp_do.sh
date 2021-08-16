#!/bin/bash
for f in `cat servers.txt`; do echo "### $f ###"; scp -i 1020750-private.pem $1 1020750@$f:$2; done
