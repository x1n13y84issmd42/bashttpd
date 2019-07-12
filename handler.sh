#!/bin/bash

source bwf.sh
source router.sh

rxHeader='^([a-zA-Z-]+)\s*:\s*(.*)'
rxMethod='^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP' #doesn't work

PROJECT=$1

parserMode="headers"
reqBodyLen=0

let reqBodyLen=0

# Reading headers
while read INPUT; do
	if [ $parserMode = "headers" ]; then
		if [[ $INPUT =~ $rxHeader ]] && [ $parserMode = "headers" ]; then
			headerName=${BASH_REMATCH[1]}
			headerValue=${BASH_REMATCH[2]}

			# Trimming off whitespace
			headerValue="$(echo -e "${headerValue}" | sed -r 's/\s+//g')"

			# log "Header $headerName is '$headerValue'"

			# Replacing - with _ in header names and uppercasing them
			headerName="$(echo -e "${headerName}" | sed -r 's/-/_/g' | sed -e 's/\(.*\)/\U\1/g')"

			# This creates variables named after header names with header values
			printf -v $headerName "$headerValue"

		# Figuring out the request method used
		elif [[ $INPUT =~ ^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP ]] && [ $parserMode = "headers" ]; then
			reqMethod=${BASH_REMATCH[1]}
			reqPath=${BASH_REMATCH[2]}
			log ""
			log "Request is $reqMethod @ $reqPath"

		# Done with headers
		else
			break
		fi
	fi
done

BODY=""

# Reading body, 1 char at a time
# Regular read can't get the last line because of missing newline there
if [ -z ${CONTENT_LENGTH+x} ]; then
	:
else
	while [ $reqBodyLen -lt $CONTENT_LENGTH ]; do
		read -n1 CHAR
		BODY="$BODY$CHAR"
		let reqBodyLen=reqBodyLen+1
	done;
fi

# Figuring out the content boundary in case we have a multipart/form-data Content-Type
if [[ $CONTENT_TYPE =~ ^multipart\/form\-data ]]; then
	CONTENT_BOUNDARY="$(echo $CONTENT_TYPE | sed -n 's/.*data\;boundary=\(.*\)/\1/p')"
fi

# Cleaning Content-Type if it has stuff after ;
if [[ $CONTENT_TYPE =~ \; ]]; then
	CONTENT_TYPE="$(echo $CONTENT_TYPE | sed -n 's/\(.*\);.*/\1/p')"
fi

# log "-- Content Type is $CONTENT_TYPE"
# log "-- Content Boundary is $CONTENT_BOUNDARY"
# log "-- Content Length is $CONTENT_LENGTH"
# log "-- Request body length $reqBodyLen"
# log "--------------------------------------------"

# echo "$BODY" > reqbody

# Making the Bashttpd Web Framework available for controller scripts as 'source $BWF'
export BWF="$(realpath ./bwf.sh)"

router
