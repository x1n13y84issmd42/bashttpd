#!/bin/bash

source bwf.sh
source router.sh

rxHeader='^([a-zA-Z-]+)\s*:\s*(.*)'
rxMethod='^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP' #doesnt work

PROJECT=$1

parserMode="headers"
reqBodyLen=0

LANG=C LC_ALL=C

function bytelen {
	echo $(printf "%s" "$@" | wc --bytes)
}

function charlen {
	echo $(printf "%s" "$@" | wc --chars)
}

let reqBodyLen=0

# readarray LINES
# for INPUT in "${LINES[@]}"; do
while read INPUT; do
	if [ $parserMode = "headers" ]; then
		if [[ $INPUT =~ $rxHeader ]] && [ $parserMode = "headers" ]; then
			headerName=${BASH_REMATCH[1]}
			headerValue=${BASH_REMATCH[2]}

			# Trimming the whitespace
			headerValue="$(echo -e "${headerValue}" | sed -r 's/\s+//g')"

			log "Header $headerName is '$headerValue'"

			# Replacing - with _ in header names and uppercasing them
			headerName="$(echo -e "${headerName}" | sed -r 's/-/_/g' | sed -e 's/\(.*\)/\U\1/g')"

			# This creates variables named after header names with header values
			printf -v $headerName "$headerValue"

		elif [[ $INPUT =~ ^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP ]] && [ $parserMode = "headers" ]; then
			reqMethod=${BASH_REMATCH[1]}
			reqPath=${BASH_REMATCH[2]}
			log "Serving $reqMethod @ $reqPath"

		else
			break
		fi
	fi
done

BODY=""

while [ $reqBodyLen -lt $CONTENT_LENGTH ]; do
	read -n1 CHAR
	BODY="$BODY$CHAR"
	let reqBodyLen=reqBodyLen+1
done;

log "-- User Agent is $USER_AGENT"
log "-- Content Length is $CONTENT_LENGTH"
log "-- Request body length $reqBodyLen"

# echo "$BODY" > reqbody

# Making the Bashttpd Web Framework available for controller scripts as 'source $BWF'
export BWF="$(realpath ./bwf.sh)"

router
