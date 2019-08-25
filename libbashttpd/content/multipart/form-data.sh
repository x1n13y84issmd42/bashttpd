_IFS=$IFS
IFS=$''
LANG=C
LC_ALL=C

CL=0

CHUNK_SIZE=2000
CLT=$CHUNK_SIZE

function renderProgress {
	echo -en "\r	Read $CL/$CONTENT_LENGTH bytes " >&2
	local n=$(($CLT/$CHUNK_SIZE))
	local mark="="
	local numMarks=40
	local markCLT=$(($CONTENT_LENGTH/$numMarks))

	echo -En "[" >&2

	for ((i=0; i<$CL; i+=$markCLT)); do
		echo -En "$mark" >&2
	done

	for ((i=$CL; i<$CONTENT_LENGTH; i+=$markCLT)); do
		echo -En " " >&2
	done
	
	echo -n "] " >&2
}

# Reads from input until the supplied predicate function returns 0,
# and dumps the contents to a specified file.
# Usage:
#	dumpUntil CRLFFound $tmp - reads until found a \r\n sequence and dumps the data to the $tmp file
function dumpUntil {
	loggggg "	Dumping fast to $2 until $1"
	LINE=""
	# loggggg ""

	if [[ ! -z $X_BWF_UPLOAD_ID ]]; then
		# Going to report the progress
		loggggg "	Upload ID is \"$X_BWF_UPLOAD_ID\", going to report the upload progress to the client."
		echo "HTTP/1.1 200"
		echo "Content-Type: application/javascript"
		echo ""
	fi

	while [ $CL -lt $CONTENT_LENGTH ]; do
		read -r -d '' -n1 CHAR
		let CL=CL+1
		
		# Slashes interfere with \x00
		[[ $CHAR == "\\" ]] && CHAR="\x5c"
		[[ -z $CHAR ]] && CHAR="\x00"

		LINE="$LINE$CHAR"

		# Making sure the chunking won't chunk the last content boundary line,
		# and CB parsers are able to detect it, so leaving a padding.
		CLREM=$(($CONTENT_LENGTH-$CL))
		CB_PADDING=$((${#CONTENT_BOUNDARY}+10))
		if [[ $CL -ge $CLT ]] && [[ $CLREM -gt $CB_PADDING ]]; then
			echo -en $LINE >> $2
			LINE=""

			CLT=$((CLT+CHUNK_SIZE))
			renderProgress;

			if [[ ! -z $X_BWF_UPLOAD_ID ]]; then
				# Reporting the progress as JS to the client.
				echo "bwf.renderUploadProgress($CL, $CONTENT_LENGTH);"
			fi
		fi

		# Testing & breaking
		if $1; then
			if [[ ${#LINE} > 0 ]]; then
				echo -en $LINE >> $2
				LINE=""
			fi
			
			renderProgress;

			return 0
		fi
	done;

	return 255
}

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

		let CLR=$CL%500
		if [[ $CLR == 0 ]]; then
			local safechar=$(echo -n "$CHAR" | tr '\n' '\\')
			loggggg "	READ   $CL/$CONTENT_LENGTH		$hexchar ($safechar)"
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
	SEP=$'\r\n'"$CB"
	if [[ ${LINE:${#LINE}-$LEN:$LEN} == $SEP ]]; then
		loggggg "	Found a content boundary"
		LINE=${LINE::-$LEN}
		return 0
	fi

	return 255
}

# Looks for a Content-Disposition line and extract param	eter and file names from it.
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
		# Not setting NEXT_PARSER because parseContent will read the input itself.
		parseContent
		return 0
	fi

	return 255 # evaluates as false in parseCRLF_or_ContentType
}

# Reads a part of the request body until encounters a content boundary value.
function parseContent {

	loggggg "	Reading the request body"
	T=$(sys.TimeElapsed)

	if [[ -z $CURRENT_FILENAME ]]; then
		readUntil CRLFBoundaryFound
		T=$(sys.TimeElapsed)
		loggggg "	Took $T seconds to read the request body."

		# Regular values are stored as variables.
		var "DATA_$CURRENT_PARAMETER" "$LINE"
		loggggg "	Set DATA_$CURRENT_PARAMETER to \"$LINE\""
	else
		# Uploaded files are stored in /tmp...
		tmp=$(mktemp)
		T=$(sys.TimeElapsed)
		dumpUntil CRLFBoundaryFound $tmp
		T=$(sys.TimeElapsed)
		loggggg "	Took $T seconds to read the request body."

		# ...and their filenames are stored as variables.
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
		renderProgress;
		log ""
		NEXT_PARSER=parseNothing
		return 0
	fi
}

NEXT_PARSER=parseContentDisposition

if ! [ -z ${CONTENT_LENGTH+x} ]; then
	readUntil BoundaryFound
	let LI=0

	T1=$(sys.Time)
	while readUntil CRLFFound; do
		let LI=$LI+1
		loggggg "Line #$LI is ($LINE) (${#LINE} chars)"
		loggggg "The parser is $NEXT_PARSER"

		[[ ! -z $NEXT_PARSER ]] && $NEXT_PARSER

		loggggg ""
	done 
	
	T2=$(sys.Time)
	T=$(($T2-$T1))
	loggggg "Done in $T seconds."
	
	# Debug dump
	[[ ! -z $DEBUG_DUMP_BODY ]] && echo -n "$BODY" > $DEBUG_DUMP_BODY
fi

# An implementation of req.Data.
function req.DataImpl {
	vn="DATA_$1"
	yield ${!vn}
}

IFS=$_IFS