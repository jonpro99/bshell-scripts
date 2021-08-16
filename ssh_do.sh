#!/bin/bash
for f in `cat servers.txt`; do echo "### $f ###\n"; ssh -tt $f "$1"; done
