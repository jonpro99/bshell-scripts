#!/bin/bash

servers=`cat lustre.txt`
for f in $servers; do echo "### $f ###"; ssh -tt -i lustre.pem root@$f "$1"; done

