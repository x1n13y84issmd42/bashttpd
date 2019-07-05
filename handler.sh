#!/bin/bash

source router.sh

echo "SHTTP"
echo "Project: $1"

rxHeader='^([a-zA-Z-]+)\s*:\s*(.*)'
rxMethod='^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP' #doesnt work

while read INPUT;
do
	# echo "AA${INPUT}AA"

	if [[ $INPUT =~ $rxHeader ]]; then
		headerName=${BASH_REMATCH[1]}
		headerValue=${BASH_REMATCH[2]}

		# Trimming the leading whitespace
		headerValue="$(echo -e "${headerValue}" | sed -r 's/\s+//g')"

		echo "Header $headerName is '$headerValue'"

		# Replacing - with _ in header names and uppercasing it
		headerName="$(echo -e "${headerName}" | sed -r 's/-/_/g' | sed -e 's/\(.*\)/\U\1/g')"

		# This creates variables names after header names with header values
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
		echo $INPUT		
		router "$1$path"
	fi

done;

echo "-- Host is $HOST"
echo "-- Connection is $CONNECTION"
echo "-- User Agent is $USER_AGENT"
