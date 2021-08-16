#!/usr/bin/env bash

## Before doing anything, are we running as root?
if [[ $EUID -ne 0 ]]; then
	echo "[ERROR] This test must run as root. Exit status: XCCDF_RESULT_ERROR" 1>&2
	exit $XCCDF_RESULT_ERROR
else

	## NOTE: yum check-update return codes:
	# 100: 	packages to update
	# 0:	no packages to update
	# 1:	error
	YUMCHECK=`yum check-update --cve $1 --advisory $2 > /dev/null 2>&1`

	case $YUMCHECK in
	100)
		## packages to update
		exit $XCCDF_RESULT_FAIL
		;;
	0)
		## no packages to update
		exit $XCCDF_RESULT_PASS
		;;
	1)
		exit $XCCDF_RESULT_ERROR
		;;
	esac
fi

