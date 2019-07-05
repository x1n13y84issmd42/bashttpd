#!/bin/bash

source router.sh

echo "Bashttpd 0.1"
echo "Project: $1"

rxHeader='^([a-zA-Z-]+)\s*:\s*(.*)'
rxMethod='^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP' #doesnt work

while read INPUT;
do
	if [[ $INPUT =~ $rxHeader ]]; then
		headerName=${BASH_REMATCH[1]}
		headerValue=${BASH_REMATCH[2]}

		# Trimming the whitespace
		headerValue="$(echo -e "${headerValue}" | sed -r 's/\s+//g')"

		echo "Header $headerName is '$headerValue'"

		# Replacing - with _ in header names and uppercasing them
		headerName="$(echo -e "${headerName}" | sed -r 's/-/_/g' | sed -e 's/\(.*\)/\U\1/g')"

		# This creates variables named after header names with header values
		printf -v $headerName "$headerValue"

	elif [[ $INPUT =~ ^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP ]]; then
		method=${BASH_REMATCH[1]}
		path=${BASH_REMATCH[2]}
		echo "Request method is $method"
		echo "Request path is $path"

	# elif [[ $INPUT =~ ^\s+ ]]; then
	# elif [ -z $INPUT ]; then
	else
		echo "--------------------------"
		# echo $INPUT		
		break
	fi
done;

echo "-- Host is $HOST"
echo "-- Connection is $CONNECTION"
echo "-- User Agent is $USER_AGENT"

router "$1$path"
