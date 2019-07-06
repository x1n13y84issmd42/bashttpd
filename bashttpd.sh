#!/bin/bash

echo "Bashttpd 0.1"
echo "Project: $1"

netcat -lvk -p 8080 -c "./handler.sh $1"