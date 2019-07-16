#!/bin/bash

echo "Bashttpd 0.2"
echo "Project: $1"

while true; do
	netcat -l -k -p 8080 -c "./handler.sh $1"
	ncxc=$?
	if [ $ncxc -gt 0 ]; then
		echo "Exited with $ncxc"
		echo "It was nice having you here. Come back one day."
		break;
	fi
done