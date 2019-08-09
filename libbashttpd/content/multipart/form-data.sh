_IFS=$IFS
# IFS=$'\r'
IFS=$''
LANG=C
LC_ALL=C

CL=0

# Reads from input until the supplied predicate function returns 0
# Usage:
#	readUntil CRLFFound - reads until found a \r\n sequence
function readUntil {
	LINE=""
	HEXLINE=""
	while [ $CL -lt $CONTENT_LENGTH ]; do
		read -r -d '' -n1 CHAR
		let CL=CL+1
		LINE="$LINE$CHAR"

		# The single quote turns $CHAR into a number
		local hexchar=$(printf "%02x" "'$CHAR")
		# Fixing zero-bytes
		[[ -z $hexchar ]] && hexchar="00"
		HEXLINE="$HEXLINE\x$hexchar"

		let CLR=$CL%500
		if [[ $CLR == 0 ]]; then
			local lochar=$(echo -n "$CHAR" | tr '\n' '\\')
			loggggg "* * * * DONE READIN   $CL/$CONTENT_LENGTH		$hexchar ($lochar)"
		fi

		# Testing & breaking
		if $1; then
			return 0
		fi
	done;

	return 255
}

# A predicate function for readUntil.
# Stops when a content boundary is encountered.
function BoundaryFound {
	if [[ $LINE =~ "$CONTENT_BOUNDARY"$ ]]; then
		return 0
	fi

	return 255
}

# A predicate function for readUntil.
# Stops when a CRLF is encountered.
function CRLFFound {
	if [[ ${LINE:${#LINE}-2:2} == $'\r\n' ]]; then
		LINE=${LINE::-2}
		HEXLINE=${HEXLINE::-8}
		return 0
	fi

	return 255
}

# A predicate function for readUntil.
# Stops when a CRLF followed by a content boundary is encountered.
function CRLFBoundaryFound {
	# The '--' are required by RFC https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
	CB="--$CONTENT_BOUNDARY"
	let LEN=${#CB}+2
	let HEXLEN=$LEN*4
	SEP=$'\r\n'"$CB"
	if [[ ${LINE:${#LINE}-$LEN:$LEN} == $SEP ]]; then
		LINE=${LINE::-$LEN}
		HEXLINE=${HEXLINE::-$HEXLEN}
		return 0
	fi

	return 255
}

# Looks for a Content-Disposition line and extract parameter and file names from it.
function parseContentDisposition {
	if [[ $LINE =~ Content-Disposition: ]]; then
		loggggg "	Found a Content-Disposition"
		# Found a content disposition, extracting a parameter name from it
		CURRENT_PARAMETER=$(echo -e $LINE | sed -rn 's/.* name\=\"([^"]*)\";{0,1}.*/\1/p')
		loggggg "	Found a parameter \"$CURRENT_PARAMETER\""

		if [[ $LINE =~ ' 'filename= ]]; then
			# Found a 'filename=' substring, extracting a file name from it
			CURRENT_FILENAME=$(echo -e $LINE | sed -rn 's/.* filename\=\"([^"]*)\";{0,1}.*/\1/p')
			loggggg "	Found a filename \"$CURRENT_FILENAME\""
		fi

		NEXT_PARSER=parseCRLF_or_ContentType

		return 0
	fi
	
	return 255
}

function parseCRLF {
	if [[ -z $LINE ]]; then
		loggggg "	Found a CRLF, proceeding to the content body"
		# NEXT_PARSER=parseContent
		parseContent
		return 0
	fi

	return 255 # evaluates as false in parseCRLF_or_ContentType
}

# Reads a part of the request body until encounters a content boundary value.
function parseContent {
	loggggg "	Reading the request body"
	$(sys.TimeElapsed)
	readUntil CRLFBoundaryFound
	T=$(sys.TimeElapsed)
	loggggg "	Took $T seconds to read the request body."

	if [[ -z $CURRENT_FILENAME ]]; then
		# Regular values are stored as variables.
		var "DATA_$CURRENT_PARAMETER" "$LINE"
		loggggg "	Set DATA_$CURRENT_PARAMETER to \"$LINE\""
	else
		# Uploaded files are stored in /tmp
		tmp=$(mktemp)
		echo -en $HEXLINE > $tmp
		var "FILE_$CURRENT_PARAMETER" $tmp
		var "FILENAME_$CURRENT_PARAMETER" $CURRENT_FILENAME
		var "FILECT_$CURRENT_PARAMETER" $CURRENT_CONTENT_TYPE
		loggggg "	Saved \"$CURRENT_FILENAME\" as $tmp"
	fi

	NEXT_PARSER=parseContentDisposition_or_Fin

	CURRENT_FILENAME=""
	CURRENT_PARAMETER=""
	CURRENT_CONTENT_TYPE=""
}

# Multipart data sometimes has it's own Content-Type
function parseContentType {
	if [[ $LINE =~ Content-Type: ]]; then
		CURRENT_CONTENT_TYPE=$(echo -nE "$LINE" | sed -r 's/\s+//g' | sed -\n 's/.*:\s*\(.*\)/\1/p')
		loggggg "	Found a Content-Type of '$CURRENT_CONTENT_TYPE', proceeding to a CRLF"
		NEXT_PARSER=parseCRLF
		return 0
	fi

	return 255
}

function parseNothing {
	return 0
}

function parseCRLF_or_ContentType {
	if ! parseCRLF; then
		parseContentType
	fi
}

function parseContentDisposition_or_Fin {
	if ! parseContentDisposition; then
		parseFin
	fi
}

function parseFin {
	loggggg "parseFin"
	if [[ $LINE = "--" ]]; then
		loggggg "	Found the request end."
		NEXT_PARSER=parseNothing
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
		loggggg "Line #$LI is ($LINE) (${#LINE} chars)"
		loggggg "The parser is $NEXT_PARSER"

		[[ ! -z $NEXT_PARSER ]] && $NEXT_PARSER

		loggggg ""
	done 
	
	# Debug dump
	[[ ! -z $DEBUG_DUMP_BODY ]] && echo -n "$BODY" > $DEBUG_DUMP_BODY
fi

# An implementation of reqData.
function reqDataImpl {
	vn="DATA_$1"
	yield ${!vn}
}

IFS=$_IFS