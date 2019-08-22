#!/bin/bash

echo "Bashttpd 0.6"
echo "Project: $1"

while true; do
	netcat -l -k -p 8080 -c "./libbashttpd/handler.sh $1"
	ncxc=$?
	echo ""
	if [ $ncxc -gt 0 ]; then
		echo "Exited with $ncxc"
		echo "It was nice having you here. Come back one day."
		break;
	fi
done