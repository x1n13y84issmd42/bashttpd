rxHeader='^([a-zA-Z-]+)\s*:\s*(.*)'
rxMethod='^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP' #doesn't work

function readHeaders {
	while read INPUT; do
		if [[ $INPUT =~ $rxHeader ]]; then
			headerName=${BASH_REMATCH[1]}
			headerValue=${BASH_REMATCH[2]}

			# Trimming off whitespace
			headerValue="$(echo -e "${headerValue}" | sed -r 's/\s+//g')"

			# log "Header $headerName is '$headerValue'"

			# Replacing - with _ in header names and uppercasing them
			headerName="$(echo -e "${headerName}" | sed -r 's/-/_/g' | sed -e 's/\(.*\)/\U\1/g')"

			# This creates variables named after header names with header values
			var $headerName "$headerValue"

		# Figuring out the request method used
		elif [[ $INPUT =~ ^(GET|POST|PUT|DELETE|OPTIONS)" "+(.*)" "+HTTP ]]; then
			reqMethod=${BASH_REMATCH[1]}
			reqPath=${BASH_REMATCH[2]}
			log "Request is $reqMethod @ $reqPath"

		# Done with headers
		else
			log "Done with headers"
			break
		fi
	done
}

function normalizeHeaders {
	# Figuring out the content boundary in case we have a multipart/form-data Content-Type
	if [[ $CONTENT_TYPE =~ ^multipart\/form\-data ]]; then
		CONTENT_BOUNDARY="$(echo $CONTENT_TYPE | sed -n 's/.*data\;boundary=\(.*\)/\1/p')"
	fi

	# Cleaning Content-Type if it has stuff after ;
	if [[ $CONTENT_TYPE =~ \; ]]; then
		CONTENT_TYPE="$(echo $CONTENT_TYPE | sed -n 's/\(.*\);.*/\1/p')"
	fi
}

function readBody {
	# Choosing a parser for the rest of request data based on Content-Type
	case $CONTENT_TYPE in
		"multipart/form-data")
			source libbashttpd/content/multipartFormData.sh
		;;

		"application/x-www-form-urlencoded")
			source libbashttpd/content/XWWWFormURLEncoded.sh
		;;

		*)
			log "The Content-Type \"$CONTENT_TYPE\" is not supported yet. Please implement and submit a pull request @ github.com/x1n13y84issmd42/bashttpd"
		;;
	esac
}