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

# Outputs Content-Type of the uploaded file.
function reqFileContentType {
	vn="FILECT_$1"
	yield ${!vn}
}

# A shorthand function to responding with JSONs. Encodes passed data, sends Content-Type.
# Arguments
#	$1: a name of a variable containing response data. Not the var itself.
#	$2: an optional encoding mode for JSON.EncodeObject & EncodeArray functions.
function respJSON {
	type=$(reflection.Type $1)

	case $type in
		"MAP")
			JSON=$(JSON.EncodeObject $1 $2)
		;;

		"ARRAY")
			JSON=$(JSON.EncodeArray $1 $2)
		;;

		"STRING")
			JSON=$(JSON.EncodeString $1)
		;;

		*)
			JSON=$(JSON.EncodePass $1)
		;;
	esac

	respHeader "Content-Type" "application/json"
	respBody $JSON
}

# Encodes an associative array as a JSON object.
# Arguments:
#	$1: name of the array to encode. Note, it's name, not the array itself.
#	$2: an optional "untyped" flag to enable proper JSON types for fields.
#	When omitted, the values go to JSON as is, without any additional encoding.
function JSON.EncodeObject {
	declare -a JSONFIELDS
	decl=$(declare -p $1)
	eval "declare -A INPUT=${decl#*=}"

	for IK in "${!INPUT[@]}"; do
		SRCVAL=${INPUT[$IK]}
		JSONVAL=$SRCVAL

		if [[ $2 == 'untyped' ]]; then
			type=$(reflection.Type SRCVAL)

			case $type in
				"STRING")
					JSONVAL=$(JSON.EncodeString SRCVAL)
				;;

				*)
					JSONVAL=$(JSON.EncodePass SRCVAL)
				;;
			esac
		fi

		JSONFIELDS+=("\"$IK\":$JSONVAL")
	done

	JSON=$(array.join ", " ${JSONFIELDS[@]})
	JSON="{$JSON}"

	yield $JSON
}

# Encodes an associative array as a JSON array.
# Arguments:
#	$1: name of the array to encode. Note, it's name, not the array itself.
#	$2: an optional "untyped" flag to enable proper JSON types for values.
#	When omitted, the values go to JSON as is, without any additional encoding.
function JSON.EncodeArray {
	declare -a JSONFIELDS
	decl=$(declare -p $1)
	eval "declare -A INPUT=${decl#*=}"

	for IK in "${!INPUT[@]}"; do
		SRCVAL=${INPUT[$IK]}
		JSONVAL=$SRCVAL
		type=$(reflection.Type SRCVAL)

		if [[ $2 == 'untyped' ]]; then
			case $type in
				"STRING")
					JSONVAL=$(JSON.EncodeString SRCVAL)
				;;

				*)
					JSONVAL=$(JSON.EncodePass SRCVAL)
				;;
			esac
		fi

		JSONFIELDS+=("$JSONVAL")
	done

	JSON=$(array.join ", " ${JSONFIELDS[@]})
	JSON="[$JSON]"

	yield $JSON
}

# Encodes a value as a JSON string.
# Takes name of the variable as a argument.
# It's name, not the variable itself.
function JSON.EncodeString {
	val=$(eval echo \$${1})
	yield "\"$val\""
}

# Encodes a value as a JSON value, i.e. doesn't change it in any way.
# Takes name of the variable as a argument.
# It's name, not the variable itself.
function JSON.EncodePass {
	val=$(eval echo \$${1})
	yield "$val"
}

TIMER_LAST=$(date +%s)

function sys.Time {
	date +%s
}

function sys.TimeElapsed {
	T=$(date +%s)
	DT=$((T-TIMER_LAST))
	TIMER_LAST=$T
	yield "$DT"
}