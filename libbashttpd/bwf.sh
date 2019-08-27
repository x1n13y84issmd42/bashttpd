# Bashttpd Web Framework

shopt -s expand_aliases

# Sends an HTTP response status code.
function resp.Status {
	[[ -z $__HTTP_STATUS_SENT ]] && echo "HTTP/1.1 $1" && __HTTP_STATUS_SENT=$1 && loggg "	${lcLGray}resp.Status${lcX} HTTP/1.1 ${lcWhite}$1"
}

# Sends an HTTP response header.
function resp.Header {
	echo "$1: $2"
	loggg "	${lcLGray}resp.Header${lcX} ${lcYellow}$1${lcX}: ${lcWhite}$2"
}

# Sends an HTTP response body.
function resp.Body {
	echo ""
	echo -E "$1"
	loggg "	${lcLGray}resp.Body${lcX} ${lcWhite}[...]"
}

# Responds with file contents.
# Doesn't care about neither content length nor it's type. Expects you to do it.
function resp.File {
	echo ""
	cat "$1"
	loggg "	${lcLGray}resp.File${lcX} ${lcWhite}$1"
}

# Reads a file, expands variables in it, then responds.
function resp.TemplateFile {
	echo ""

	tplFilePath="$PROJECT/.etc/tpl/$1"
	tmp=$(mktemp --suffix=.sh)

	echo 'cat <<END_OF_TEXT' >  $tmp
	cat "$tplFilePath"       >> $tmp
	echo ""                  >> $tmp
	echo 'END_OF_TEXT'       >> $tmp

	source $tmp
	loggg "	${lcLGray}resp.TemplateFile${lcX} ${lcWhite}\"$1\""
}

# Sets a response cookie.
function resp.Cookie {
	resp.Header "Set-Cookie" "$1=$2; Path=/"
}

# Outputs a value of a single cookie from the $COOKIE header.
function req.Cookie {
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

# Outputs a single value from the request body of structured
# requests (JSON, form data),regardless of it's Content-Type.
# See actual parsers in libbashttpd/content
# Arguments:
#	$1: parameter name.
#	$2: optional output reference name.
function req.Data {
	if [ -z $CONTENT_TYPE ]; then
		echo ""
		return 0
	fi

	local r
	# req.DataImpl must be declared by a content parser in it's own file.
	r=$(req.DataImpl $1)
	api.Error "req.DataImpl" $? "$r"
	yield "$r" $2
}

# Outputs a temporary file name where contents of the uploaded file is stored.
function req.File {
	vn="FILE_$1"
	yield ${!vn}
}

# Outputs original name of the uploaded file.
function req.FileName {
	vn="FILENAME_$1"
	yield ${!vn}
}

# Outputs Content-Type of the uploaded file.
function req.FileContentType {
	vn="FILECT_$1"
	yield ${!vn}
}

# Outputs a values of a query string parameter.
# Arguments:
#	$1: name of the request query string parameter.
#	$2: optional reference name to put the value into.
function req.Query {
	vn="QS_$1"
	yield "${!vn}" "$2"
}

# A shorthand function to responding with JSONs. Encodes passed data, sends Content-Type.
# In case of enabled upload progress reporting, it responds with a JSONP and stores the response
# under the "X-Bwf-Upload-ID" value.
# Arguments
#	$1: a name of a variable containing response data. Not the var itself.
#	$2: an optional encoding mode for JSON.EncodeObject & EncodeArray functions.
function resp.JSON {
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

	if [[ ! -z $X_BWF_UPLOAD_ID ]]; then
		loggggg "Upload ID is \"$X_BWF_UPLOAD_ID\", responding as JSONP."
		resp.Body "bwf.set(\"$X_BWF_UPLOAD_ID\", $JSON);"
		resp.Body "console.log(\"set the $X_BWF_UPLOAD_ID\");"
	else
		resp.Header "Content-Type" "application/json"
		resp.Body "$JSON"
	fi
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
			# log "JSON.EncodeObject Type of SRCVAL is $type"

			case $type in
				"STRING")
					JSONVAL="$(JSON.EncodeString SRCVAL)"
				;;

				*)
					JSONVAL="$(JSON.EncodePass SRCVAL)"
				;;
			esac
		fi

		JSONFIELDS+=("\"$IK\":$JSONVAL")
	done

	IFS=''
	JSON=$(array.join ", " "${JSONFIELDS[@]}")
	JSON="{$JSON}"
	yield "$JSON"
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

	IFS=''
	JSON=$(array.join ", " ${JSONFIELDS[@]})
	JSON="[$JSON]"

	yield "$JSON"
}

# Encodes a value as a JSON string.
# Takes name of the variable as a argument.
# It's name, not the variable itself.
function JSON.EncodeString {
	s=$1
	val=$(eval echo "\$${s}")
	val=${val//$'\n'/\\n}
	val=${val//'"'/\\\"}
	yield "\"$val\""
}

# Encodes a value as a JSON value, i.e. doesn't change it in any way.
# Takes name of the variable as a argument.
# It's name, not the variable itself.
function JSON.EncodePass {
	val=$(eval echo \$${1})
	[[ -z $val ]] && val='""'
	yield "$val"
}

TIMER_LAST=$(date +%s)

# Outputs current timestamp in seconds.
function sys.Time {
	date +%s
}

# Outputs the time elapsed since previous call to this function. 
function sys.TimeElapsed {
	T=$(date +%s)
	DT=$((T-TIMER_LAST))
	TIMER_LAST=$T
	yield "$DT"
}

# Checks if a progrma is installed in the system.
# For use in if conditions.
function sys.Installed {
	local prog=$(command -v $1)
	if [[ -z $prog ]]; then
		return 255
	else
		return 0
	fi
}

# Executes a MySQL binary and provides auth credentials.
function mysql.Run {
	if ! sys.Installed mysql; then
		error "MySQL is not installed."
		return 255
	fi

	[[ ! -z $MYSQL_PASSWORD ]] && PSWD="-p $MYSQL_PASSWORD"
	loggggg "mysql.Run: mysql --host $MYSQL_HOST -u $MYSQL_USER $PSWD $@"
	mysql --host $MYSQL_HOST -u $MYSQL_USER $PSWD $@ 2>&1
}

# Executes a MySQL query.
# Arguments:
#	$1: a query to execute.
#	$2: optional reference name to store the result
function mysql.Query {
	local r
	r=$(mysql.Run $MYSQL_DB -e "$1")
	local __xc=$?
	yield "$r" $2
	return $__xc
}

# Executes a SELECT MySQL query with a WHERE sattement.
# Arguments:
#	$1: a table name to select rows from
#	$2: a 'WHERE' clause without the "WHERE" keyword
#	$3: optional reference name to store the result
function mysql.Select {
	local r
	r=$(mysql.Query "SELECT * FROM $1 WHERE $2")
	api.Error "mysql.Select" $? "$r"

	yield "$r" $3
}

# Executes a "SELECT *" MySQL query, returns all available rows.
# Arguments:
#	$1: a table name to select rows from
#	$2: optional reference name to store the result
function mysql.All {
	local r
	r=$(mysql.Query "SELECT * FROM $1")
	api.Error "mysql.Select" $? "$r"

	yield "$r" $2
}

# Iterates over a set of rows returned from mysql.
# Context:
#	$ROWS - raw text output from mysql
alias mysql.foreach="
IFS=\$' \\t\\r\\n'
declare -a sqlHeader
declare -a sqlLines
declare -a sqlColumns
readarray -t AROWS <<< \$ROWS
for i in \${!AROWS[@]}; do
	[[ \$i == 0 ]] && sqlHeader=(\${AROWS[0]}) || sqlLines+=(\"\${AROWS[\$i]}\")
done; for lI in \${!sqlLines[@]};"


# Declares a local associative array and puts mysql row data in it.
# Context:
#	must be executed within a mysql.foreach loop
#	declares a $row associative array with row data inside
alias mysql.row="
IFS_backup=\$IFS
IFS='\t'
readarray -d $'\\t' -t sqlColumns <<< \${sqlLines[\$lI]}
declare -A row
for colI in \${!sqlColumns[@]}; do
	row[\${sqlHeader[\$colI]}]="\${sqlColumns[\$colI]}"
done
IFS=\$IFS_backup"

# Inserts a row into a MySQL table.
# Arguments:
#	$1: table name.
#	$2: name of the associative array which contains column data.
#	$3: optional reference name to store the ID of the inserted record.
function mysql.Insert {
	declare -a keys
	declare -a vals
	array.getbyref2
	array.foreach; do
		keys+=("$key")
		#TODO: escape quotes and stuff
		vals+=("\"${E[$key]}\"")
	done

	skeys=$(array.join ', ' ${keys[@]})
	skeys="($skeys)"
	svals=$(array.join ', ' ${vals[@]})
	svals="($svals)"

	local ROWS
	ROWS=$(mysql.Query "INSERT INTO $1 $skeys VALUES $svals; SELECT LAST_INSERT_ID() as ID;")
	api.Error "mysql.Insert" $? "$ROWS"

	mysql.foreach do
		mysql.row
		yield "${row[ID]}" $3
		return 0
	done
}

# Installs a project MySQL database.
function mysql.Install {
	IFS=''
	hasDB=$(mysql.Run -e "SHOW DATABASES;" | grep -sw $MYSQL_DB)

	if [[ -z $hasDB ]]; then
		log "Installing the database."

		log "Creating the '$MYSQL_DB' database..."
		mysql.Run -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB"

		local projDBSQL="$PROJECT/.etc/db.sql"
		if [[ -f $projDBSQL ]]; then
			log "Executing the $projDBSQL..."
			mysql.Run $MYSQL_DB < $projDBSQL
		fi

		log "Done."
	else
		log "The DB is in place."
	fi
}

# Checks the passed exit code and reports 500 to the client in case it's not 0.
# Arguments:
#	$1: an operation name, free form.
#	$2: operation's exit code.
#	$3: an error message.
function api.Error {
	IFS=''
	if [[ $2 != 0 ]]; then
		log "	${lcbgLRed}${lcWhite}Internal Server Error.${lcX}"
		log "	${lcLRed}$1 exit code is $2."
		log "	${lcLRed}$3"
		log "	${lcLRed}Reporting to client."

		resp.Status 500
		declare -A ERRRESP=(
			[command]="$1"
			[code]="$2"
			[message]="$3"
		)
		resp.JSON ERRRESP untyped
		log "	I can't even."
		exit 0
	fi
}

# Formats Bash colored output as HTML.
# Arguments:
#	$@: an array of colored CLI output lines.
function resp.CLI {
	IFS=$'\n'
	LINES=($@)
	for line in ${LINES[@]}; do
		line=${line//$'\e'\[m/"</span>"}
		line=${line//$'\e'\[K} # No idea what's that
		line=${line//$'\r'}
		line=${line// /"&nbsp;"}

		# Matches the \e[X;XX;XXm sequences
		RX=$'\e\[([0-9]{1,2}\;){0,1}([0-9]{1,2}\;){0,1}[0-9]+m'
		while [[ $line =~ $RX ]]; do

			local class=""
			fmtOptsLine=${BASH_REMATCH[0]:2}
			fmtOptsLine=${fmtOptsLine::-1}
			readarray -t -d ';' fmtOpts <<< $fmtOptsLine
			for fmt in ${fmtOpts[@]}; do
				class="$class fmt-$fmt"
			done

			HTMLtag="<span class=\"$class\">"

			# \e[0m
			[[ $fmtOptsLine == "0" ]] && HTMLtag="</span>"

			line=${line//${BASH_REMATCH[0]}/$HTMLtag}
		done
		
		HTML="$HTML<p class=\"cli-line\">$line</p>\n"
	done
	
	echo -e "$HTML"
}

# Initializes various project-wide things.
function project.Load {
	PROJECT=$(realpath $1)
	DOMAIN=${PROJECT##*/}
	[[ -f $1/.env ]] && source $1/.env

	local URL=$(project.URL)

	loggg "Project directory is ${lcWhite}$PROJECT"
	logg "Project URL is ${lcU}${lcCyan}$URL${lcX}"
}

# Yields a fully qualified project URL, with domain name and port number.
# All arguments are joined with / and used as path.
function project.URL {
	[[ $PORT != 80 ]] && uPORT=":$PORT"

	local path=$(array.join '/' $@)
	echo "http://$DOMAIN$uPORT/$path"
}

# A regular HTTP redirect response.
# Arguments:
#	$1: A URL to relocate useragent to.
#	$2: An optional 30* HTTP status code.
function resp.Redirect {
	resp.Status ${2:-302}
	resp.Header "Location" "$1"
	resp.Body ""
}
