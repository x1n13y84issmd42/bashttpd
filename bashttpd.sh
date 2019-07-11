#!/bin/bash

echo "Bashttpd 0.2"
echo "Project: $1"

while true; do
	netcat -lk -p 8080 -vv -q -1 -w -1 -c "./handler.sh $1"
	ncxc=$?
	if [ $? -gt 0 ]; then
		echo "Exit code is $ncxc"
		echo "It was nice having you here. Come back one day."
		break;
	fi
done