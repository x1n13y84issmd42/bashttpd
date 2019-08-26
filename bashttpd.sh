#!/bin/bash

echo "Bashttpd 0.8"

source libbashttpd/utility.sh
source libbashttpd/bwf.sh

[[ -f .env ]] && source .env

project.Load $1

mysql.Install

while true; do
	netcat -l -k -p $PORT -c "./libbashttpd/handler.sh $1"
	ncxc=$?
	echo ""
	if [ $ncxc -gt 0 ]; then
		echo "Exited with $ncxc"
		echo "It was nice having you here. Come back one day."
		break;
	fi
done