_IFS=$IFS
IFS=$'\n'

CL=0

echo "" > reqhexline
echo "" > reqhexcont

function readBodyLine {
	read -r LINE
	let CL=$CL+${#LINE}+${#IFS}
	let BODY_LINE_N=$BODY_LINE_N+1
}

function parseContentBoundary {
	if [[ "$LINE" =~ $CONTENT_BOUNDARY ]]; then
		# log ""
		# log ""
		# log ""
		
		CONTENT_LINE_N=0
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
		# log "Found an empty line, proceeding to the content body"
		CURRENT_CONTENT=""
		NEXT_PARSER=parseContent
		return 0
	fi

	return 255 # evaluates as false in parseEmptyLine_or_ContentType
}

function parseContentType {
	if [[ $LINE =~ Content-Type: ]]; then
		CT=$(echo -nE "$LINE" | sed -r 's/\s+//g' | sed -\n 's/.*:\s*\(.*\)/\1/p')
		# log "Found a Content-Type of '$CT', proceeding to an empty line"
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
		# log "Another CD, starting all over"
		storeContent
		parseContentBoundary
		return
	fi

	XLINE=$LINE
	if [[ $CONTENT_LINE_N -gt 0 ]]; then
		XLINE="$LINE"
	fi

	CURRENT_CONTENT="$CURRENT_CONTENT$XLINE"

	let CONTENT_LINE_N=$CONTENT_LINE_N+1
}

function storeContent {
	# Trim the trailing \r from parameter values	
	CURRENT_CONTENT=${CURRENT_CONTENT::-1}
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
