#!/bin/bash

source bwf.sh
source router.sh

rxHeader='^([a-zA-Z-]+)\s*:\s*(.*)'
rxMethod='^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP' #doesnt work

PROJECT=$1

while read INPUT;
do
	if [[ $INPUT =~ $rxHeader ]]; then
		headerName=${BASH_REMATCH[1]}
		headerValue=${BASH_REMATCH[2]}

		# Trimming the whitespace
		headerValue="$(echo -e "${headerValue}" | sed -r 's/\s+//g')"

		# log "Header $headerName is '$headerValue'"

		# Replacing - with _ in header names and uppercasing them
		headerName="$(echo -e "${headerName}" | sed -r 's/-/_/g' | sed -e 's/\(.*\)/\U\1/g')"

		# This creates variables named after header names with header values
		printf -v $headerName "$headerValue"

	elif [[ $INPUT =~ ^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP ]]; then
		reqMethod=${BASH_REMATCH[1]}
		reqPath=${BASH_REMATCH[2]}
		log "Serving $reqMethod @ $reqPath"

	# elif [[ $INPUT =~ ^\s+ ]]; then
	# elif [ -z $INPUT ]; then
	else
		log "--------------------------"
		break
	fi
done;

# log "-- Host is $HOST"
# log "-- Connection is $CONNECTION"
# log "-- User Agent is $USER_AGENT"

export BWF="$(realpath ./bwf.sh)"

router
