# Bashttpd Web Framework

# Sends an HTTP response status code.
function respStatus {
	echo "HTTP/1.1 $1"
}

# Sends an HTTP response header.
function respHeader {
	echo "$1: $2"
}

# Sends an HTTP response body.
function respBody {
	echo ""
	echo -E $1
}

# Responds with file contents.
# Doesn't care about neither content length nor it's type. Expects you to do it.
function respFile {
	echo ""
	cat "$1"
}

# Reads a file, expands variables in it, then responds.
function respTemplateFile {
	echo ""

	tplFilePath="$PROJECT/$1"
	tmp=$(mktemp --suffix=.sh)

	echo 'cat <<END_OF_TEXT' >  $tmp
	cat "$tplFilePath"       >> $tmp
	echo ""                  >> $tmp
	echo 'END_OF_TEXT'       >> $tmp

	source $tmp
}

# Sets a response cookie.
function respCookie {
	respHeader "Set-Cookie" "$1=$2; Path=/"
}

# Outputs a value of a single cookie from the $COOKIE header.
function reqCookie {
	IFS_backup="$IFS"
	IFS=';'

	read -r -a COOKIES <<< "$COOKIE"
	for C in "${COOKIES[@]}"; do
		if [[ $C =~ ^$1= ]]; then
			echo "$(echo "$C" | sed -r 's/.*'"$1"'=(.*).*/\1/')"
			break
		fi
	done	

	IFS="$IFS_backup"
	# $(echo -e $COOKIE | sed -n 's/'"$1"'=\(.*\)/\2/p')
}

# Outputs a single value from the request body, regardless of it's Content-Type.
# See actual parsers in libbashttpd/content
function reqData {
	if [ -z $CONTENT_TYPE ]; then
		echo ""
		return 0
	fi

	# This must be declared by a content parser in it's own file.
	reqDataImpl $1
}

# Outputs a temporary file name where contents of the uploaded file is stored.
function reqFile {
	vn="FILE_$1"
	yield ${!vn}
}

# Outputs original name of the uploaded file.
function reqFileName {
	vn="FILENAME_$1"
	yield ${!vn}
}

function respJSON {
	JSON=$(JSON.EncodeObject $1)

	respHeader "Content-Type" "application/json"
	respBody $JSON
}

# Encodes an associative array as a JSON object.
# Takes name of the array as a argument.
# It's name, not the array itself.
function JSON.EncodeObject {
	declare -a JSONFIELDS
	decl=$(declare -p $1)
	eval "declare -A IA=${decl#*=}"

	for IK in "${!IA[@]}"; do
		# TODO: correct data types for numbers and booleans
		JSONFIELDS+=("\"$IK\":\"${IA[$IK]}\"")
	done

	JSON=$(join ", " ${JSONFIELDS[@]})
	JSON="{$JSON}"

	yield $JSON
}

# Encodes an associative array as a JSON array.
# Takes name of the array as a argument.
# It's name, not the array itself.
function JSON.EncodeArray {
	declare -a JSONFIELDS
	decl=$(declare -p $1)
	eval "declare -A IA=${decl#*=}"

	for IK in "${!IA[@]}"; do
		# TODO: correct data types for numbers and booleans
		JSONFIELDS+=("\"${IA[$IK]}\"")
	done

	JSON=$(join ", " ${JSONFIELDS[@]})
	JSON="[$JSON]"

	yield $JSON
}