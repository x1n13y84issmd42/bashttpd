_IFS=$IFS
# IFS=$'\r'
IFS=$''
LANG=C
LC_ALL=C

CL=0

# Reads until the supplied predicate function returns 0
# Usage:
#	readUntil CRLFFound — reads until found a \r\n sequence
function readUntil {
	LINE=""
	HEXLINE=""
	while [ $CL -lt $CONTENT_LENGTH ]; do
		read -r -d '' -n1 CHAR
		let CL=CL+1
		LINE="$LINE$CHAR"

		# Fixing zero-bytes
		local hexchar=$(echo -n "$CHAR" | xxd -ps)
		[[ -z $hexchar ]] && hexchar="00"
		HEXLINE="$HEXLINE\x$hexchar"

		# local lochar=$(echo -n "$CHAR" | tr '\n' '\\')
		# loggggg "**           DONE READIN   $CL/$CONTENT_LENGTH		$hexchar ($lochar)      **"

		# Testing & breaking
		if $1; then
			return 0
		fi
	done;

	return 255
}

function BoundaryFound {
	if [[ $LINE =~ "$CONTENT_BOUNDARY"$ ]]; then
		log "Found a Boundary"
		return 0
	fi

	return 255
}

function CRLFFound {
	if [[ ${LINE:${#LINE}-2:2} == $'\r\n' ]]; then
		log "Found a CRLF"
		LINE=${LINE::-2}
		HEXLINE=${HEXLINE::-8}
		return 0
	fi

	return 255
}

function CRLFBoundaryFound {
	# The '--' are required by RFC https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
	CB="--$CONTENT_BOUNDARY"
	let LEN=${#CB}+2
	let HEXLEN=$LEN*4
	SEP=$'\r\n'"$CB"
	if [[ ${LINE:${#LINE}-$LEN:$LEN} == $SEP ]]; then
		log "Found a CRLF-Boundary"
		LINE=${LINE::-$LEN}
		HEXLINE=${HEXLINE::-$HEXLEN}
		return 0
	fi

	return 255
}

function parseContentDisposition {
	loggggg "parseContentDisposition"
	if [[ $LINE =~ Content-Disposition: ]]; then
		# Found a content disposition, extracting a parameter name from it
		CURRENT_PARAMETER=$(echo -e $LINE | sed -rn 's/.* name\=\"([^"]*)\";{0,1}.*/\1/p')
		loggggg "Found a parameter \"$CURRENT_PARAMETER\""

		if [[ $LINE =~ ' 'filename= ]]; then
			# Found a 'filename=' substring, extracting a file name from it
			CURRENT_FILENAME=$(echo -e $LINE | sed -rn 's/.* filename\=\"([^"]*)\";{0,1}.*/\1/p')
			loggggg "Found a filename \"$CURRENT_FILENAME\""
		fi

		NEXT_PARSER=parseEmptyLine_or_ContentType

		return 0
	fi
	
	return 255
}

function parseEmptyLine {
	if [[ -z $LINE ]]; then
		loggggg "Found an empty line, proceeding to the content body"
		# NEXT_PARSER=parseContent
		parseContent
		return 0
	fi

	return 255 # evaluates as false in parseEmptyLine_or_ContentType
}

function parseContent {
	loggggg "parseContent"
	readUntil CRLFBoundaryFound

	if [[ -z $CURRENT_FILENAME ]]; then
		var "DATA_$CURRENT_PARAMETER" "$LINE"
		loggggg "Set DATA_$CURRENT_PARAMETER to \"$LINE\""
	else
		tmp=$(mktemp)
		echo -en $HEXLINE > $tmp
		var "FILE_$CURRENT_PARAMETER" $tmp
		var "FILENAME_$CURRENT_PARAMETER" $CURRENT_FILENAME

		loggggg "Saved \"$CURRENT_FILENAME\" as $tmp"
	fi

	NEXT_PARSER=parseContentDisposition_or_Fin

	# TODO: restart the parser
	# From here can follow:
	#						\r\n, Content-Disposition: ...
	#						--\r\n, i.e. end.

	CURRENT_FILENAME=""
	CURRENT_PARAMETER=""
}

function parseContentType {
	if [[ $LINE =~ Content-Type: ]]; then
		CT=$(echo -nE "$LINE" | sed -r 's/\s+//g' | sed -\n 's/.*:\s*\(.*\)/\1/p')
		loggggg "Found a Content-Type of '$CT', proceeding to an empty line"
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

function parseContentDisposition_or_Fin {
	if ! parseContentDisposition; then
		parseFin
	fi
}

function parseFin {
	log "parseFin"
	if [[ $LINE = "--" ]]; then
		log "Found the request end."
		return 0
	fi
}

NEXT_PARSER=parseContentDisposition

# Reading body, 1 char at a time
# Regular read can't get the last line because of missing newline on this Content-Type
if [ -z ${CONTENT_LENGTH+x} ]; then
	:
else
	readUntil BoundaryFound
	let LI=0

	while readUntil CRLFFound; do
		let LI=$LI+1
		log "The LINE $LI is ($LINE) (${#LINE} chars)"
		log "The parser is $NEXT_PARSER"

		$NEXT_PARSER

		log "Done. The new parser is $NEXT_PARSER."
	done 

	# readUntil CRLFFound
	# log "The LINE 1 is ($LINE) (${#LINE} chars)"

	# readUntil CRLFFound
	# log "The LINE 2 is ($LINE) (${#LINE} chars)"
	
	# readUntil CRLFFound
	# log "The LINE 3 is ($LINE) (${#LINE} chars)"

	# readUntil CRLFBoundaryFound
	# log "The after CRLFBoundaryFound LINE 4 is ($LINE) (${#LINE} chars)"
	
	# log "----------------------------------"

	# readUntil CRLFFound
	# log "The LINE 2-1 is ($LINE) (${#LINE} chars)"

	# readUntil CRLFFound
	# log "The LINE 2-2 is ($LINE) (${#LINE} chars)"

	# readUntil CRLFFound
	# log "The LINE 2-3 is ($LINE) (${#LINE} chars)"

	# readUntil CRLFFound
	# log "The LINE 2-4 is ($LINE) (${#LINE} chars)"

	# readUntil CRLFBoundaryFound
	# log "The after CRLFBoundaryFound LINE 2-5 is ($LINE) (${#LINE} chars)"
	# echo -en $HEXLINE > testdata/uploadme_rec.ico

	# readUntil CRLFFound
	# log "The LINE 2-6 is ($LINE) (${#LINE} chars)"
	
	# Debug dump
	[[ ! -z $DEBUG_DUMP_BODY ]] && echo -n "$BODY" > $DEBUG_DUMP_BODY
fi

# An implementation of reqData.
function reqDataImpl {
	vn="DATA_$1"
	yield ${!vn}
}

IFS=$_IFS