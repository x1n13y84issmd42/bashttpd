#!/bin/bash

echo "Bashttpd 0.2"
echo "Project: $1"

while true; do
	netcat -lvk -p 8080 -c "./handler.sh $1"

	if [ $? -gt 0 ]; then
		echo "It was nice having you here. Come back one day."
		break;
	fi
done