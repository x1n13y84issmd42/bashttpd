# Bashttpd Web Framework

source bodyParsers.sh

# Outputs to the host's stdout.
function log {
	echo $@ >&2
}

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

# Reads a file, expands variables in it, the responds.
function respTemplateFile {
	echo ""

	tplFilePath="$PROJECT/$1"
	tmp=$(mktemp --suffix=.sh)

	echo 'cat <<END_OF_TEXT' >  $tmp
	cat "$tplFilePath"       >> $tmp
	echo ""                  >> $tmp
	echo 'END_OF_TEXT'       >> $tmp

	source $tmp

	# echo ""
	# cat "$tmp" >&2
}

function respCookie {
	respHeader "Set-Cookie" "$1=$2; Path=/"
}

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