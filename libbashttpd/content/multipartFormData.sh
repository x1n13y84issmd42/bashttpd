_IFS=$IFS
IFS=$'\n'

CL=0

function readBodyLine {
	read -r LINE
	let CL=$CL+${#LINE}+${#IFS}
	let BODY_LINE_N=$BODY_LINE_N+1

	# Debug dump
	[[ ! -z $DEBUG_DUMP_BODY ]] && echo -nE "$LINE$IFS" > $DEBUG_DUMP_BODY
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
		# log "Found a parameter $CURRENT_PARAMETER"

		if [[ $LINE =~ ' 'filename= ]]; then
			# log "Found a filename"
			# Found a 'filename=' substring, extracting a file name from it
			CURRENT_FILENAME=$(echo -e $LINE | sed -rn 's/.* filename\=\"([^"]*)\";{0,1}.*/\1/p')
		fi

		NEXT_PARSER=parseEmptyLine_or_ContentType
	fi

}

function parseEmptyLine {
	if [ ${#LINE} == 1 ]; then
		# log "Found an empty line, proceeding to the content body"
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
		XLINE="$IFS$LINE"
	fi

	CURRENT_CONTENT="$CURRENT_CONTENT$XLINE"

	let CONTENT_LINE_N=$CONTENT_LINE_N+1
}

function storeContent {
	# Trim the trailing \r from parameter values	
	CURRENT_CONTENT=${CURRENT_CONTENT::-1}

	if [[ -z $CURRENT_FILENAME ]]; then
		var "DATA_$CURRENT_PARAMETER" "$CURRENT_CONTENT"
	else
		tmp=$(mktemp)
		echo -n "$CURRENT_CONTENT" > $tmp
		var "FILE_$CURRENT_PARAMETER" $tmp
		var "FILENAME_$CURRENT_PARAMETER" $CURRENT_FILENAME

		# log "Saved $CURRENT_FILENAME as $tmp"
	fi

	CURRENT_CONTENT=""
	CURRENT_FILENAME=""
	CURRENT_PARAMETER=""
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
