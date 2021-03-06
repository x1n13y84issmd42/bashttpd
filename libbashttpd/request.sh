IFS=''

rxHeader='^([a-zA-Z-]+)\s*:\s*(.*)'
rxMethod='^(GET|POST|PUT|DELETE|OPTIONS) +(.*) +HTTP'

# Reads HTTP request headers.
function HTTP.readHeaders {
	loggg "${lcLGray}Reading request headers"

	# Debug dump (clear)
	[[ ! -z $DEBUG_DUMP_HEADERS ]] && echo -nE "" > $DEBUG_DUMP_HEADERS
	while read INPUT; do
		# Debug dump
		[[ ! -z $DEBUG_DUMP_HEADERS ]] && echo -nE $INPUT >> $DEBUG_DUMP_HEADERS

		if [[ $INPUT =~ $rxHeader ]]; then
			headerName=${BASH_REMATCH[1]}
			headerValue=${BASH_REMATCH[2]}

			# Trimming off whitespace
			headerValue="$(echo -e "${headerValue}" | sed -r 's/\s+//g')"

			loggg "	${lcYellow}$headerName${lcX}: ${lcLGray}$headerValue${lcX}"

			# Replacing - with _ in header names and uppercasing them
			headerName="$(echo -e "${headerName}" | sed -r 's/-/_/g' | sed -e 's/\(.*\)/\U\1/g')"

			# This creates variables named after header names with header values
			var $headerName "$headerValue"

		# Figuring out the request method used
		elif [[ $INPUT =~ $rxMethod ]]; then
			reqMethod=${BASH_REMATCH[1]}
			reqURL=${BASH_REMATCH[2]}
			reqPath=${reqURL%%\?*}
			reqQuery=${reqURL#*\?}

			[[ $reqQuery == $reqPath ]] && reqQuery=""

			log "Request is ${lcLYellow}$reqMethod${lcX} @ ${lcU}${lcLCyan}$reqPath${lcX}"

			if [[ ! -z $reqQuery ]]; then
				logg "Query string is ${lcCyan}$reqQuery"

				# Parsing the query string.
				readarray -t -d '&' QSA <<< "$reqQuery"
				for QSP in ${QSA[@]}; do
					# Somehow this fixes that weird trailing \n
					QSP=$(echo "${QSP}")
					readarray -t -d '=' QSKV <<< "$QSP"
					QSK=$(echo "${QSKV[0]}")
					QSV=$(echo "${QSKV[1]}")
					QSK=$(HTTP.urldecode $QSK)
					QSV=$(HTTP.urldecode $QSV)
					var "QS_$QSK" "$QSV"
					
					loggg "	${lcCyan}$QSK${lcX} = ${lcLGray}$QSV${lxC}"
				done
			fi

		# Done with headers
		else
			loggg ""
			break
		fi
	done
}

# Pulls extra info from some headers' values, like content boundaries, strips unused stuff.
function HTTP.normalizeHeaders {
	# Figuring out the content boundary in case we have a multipart/form-data Content-Type
	if [[ $CONTENT_TYPE =~ ^multipart\/form\-data ]]; then
		CONTENT_BOUNDARY="$(echo $CONTENT_TYPE | sed -n 's/.*data\;boundary=\(.*\)/\1/p')"
	fi

	# Cleaning Content-Type if it has stuff after ;
	if [[ $CONTENT_TYPE =~ \; ]]; then
		CONTENT_TYPE="$(echo $CONTENT_TYPE | sed -n 's/\(.*\);.*/\1/p')"
	fi
}

# Reads an HTTP request body contents. Different Content-Types must be read & parsed differently,
# so it relies on specific implementations of body parsers.
function HTTP.readBody {
	if ! [[ -z $CONTENT_TYPE ]] && [[ $CONTENT_LENGTH -gt 0 ]]; then
		loggg "${lcLGray}Reading request body"

		# Choosing a parser for the rest of request data based on Content-Type
		parserFile="libbashttpd/content/$CONTENT_TYPE.sh"
		
		if [[ -f $parserFile ]]; then
			source $parserFile
		else
			log "${lcbgLRed}${lcWhite}The Content-Type \"$CONTENT_TYPE\" is not supported yet. Please implement and submit a pull request @ github.com/x1n13y84issmd42/bashttpd${lcX}"
		fi

		loggg ""
	fi
}