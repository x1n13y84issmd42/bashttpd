#!/bin/bash

source .env
source libbashttpd/utility.sh
source libbashttpd/bwf.sh

PROJECT=$1

echo "Bashttpd 0.6"
echo "Project: $PROJECT"

mysql.Install

while true; do
	netcat -l -k -p 8080 -v -c "./libbashttpd/handler.sh $1"
	ncxc=$?
	echo ""
	if [ $ncxc -gt 0 ]; then
		echo "Exited with $ncxc"
		echo "It was nice having you here. Come back one day."
		break;
	fi
done