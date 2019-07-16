_IFS=$IFS
IFS=$'\n'

CL=0

function readBodyLine {
	read -r LINE
	let CL=$CL+${#LINE}+${#IFS}
	
	if [ -z "$BODY" ]; then
		BODY="$LINE"
	else
		BODY="$BODY$IFS$LINE"
	fi
}

function parseContentBoundary {
	if [[ "$LINE" =~ $CONTENT_BOUNDARY ]]; then
		log ""
		log ""
		log ""
		
		NEXT_PARSER=parseContentDisposition
	else
		$NEXT_PARSER
	fi
}

function parseContentDisposition {
	if [[ $LINE =~ Content-Disposition: ]]; then
		# Found a content disposition, extracting a parameter name from it
		CURRENT_PARAMETER=$(echo -e $LINE | sed -rn 's/.* name\=\"([^"]*)\";{0,1}.*/\1/p')

		NEXT_PARSER=parseEmptyLine_or_ContentType
	fi
}

function parseEmptyLine {
	if [ ${#LINE} == 1 ]; then
		log "Found an empty line, proceeding to the content body"
		CURRENT_CONTENT=""
		NEXT_PARSER=parseContent
		return 0
	fi

	return 255 # evaluates as false in parseEmptyLine_or_ContentType
}

function parseContentType {
	if [[ $LINE =~ Content-Type: ]]; then
		CT=$(echo -nE "$LINE" | sed -r 's/\s+//g' | sed -\n 's/.*:\s*\(.*\)/\1/p')
		log "Found a Content-Type of '$CT', proceeding to an empty line"
		NEXT_PARSER=parseEmptyLine
		return 0
	fi
	
	return 255
}

# Sometimes there is another Content-Type, specifically for multipart content
function parseEmptyLine_or_ContentType {
	if ! parseEmptyLine; then
		parseContentType
	fi
}

function parseContent {
	# If another content boundary is encountered during body parsing - we're done here, starting all over
	if [[ $LINE =~ $CONTENT_BOUNDARY ]]; then
		log "Another CD, starting all over"
		storeContent
		parseContentBoundary
		return
	fi

	XLINE=$LINE
	if [[ $BODYLINECOUNT -gt 0 ]]; then
		XLINE="$IFS$LINE"
	fi
	
	CURRENT_CONTENT="$CURRENT_CONTENT$XLINE"
	
	let BODYLINECOUNT=$BODYLINECOUNT+1
}

function storeContent {
	#TODO: trim the trailing \r from parameter values
	log "Current content is: $CURRENT_CONTENT"
	var "DATA_$CURRENT_PARAMETER" "$CURRENT_CONTENT"
}

NEXT_PARSER=parseContentDisposition

if ! [ -z ${CONTENT_LENGTH+x} ]; then
	while true; do
		readBodyLine
		
		$NEXT_PARSER

		if [[ $CL -ge $CONTENT_LENGTH ]]; then
			break
		fi
	done
fi

IFS=$_IFS

# An implementation of reqData.
function reqDataImpl {
	vn="DATA_$1"
	yield ${!vn}
}
