# Routing of requests happens here.
# It works in 3 ways:
#	If request path exactly matches a file within the $PROJECT directory - serve the file as it is;
#	If request path exactly matches a directory within the $PROJECT directory - serve "index.html" from there;
#	Otherwise it concatenates the request path and method, adds a trailing ".sh",
#	then tries to execute the result as a controller script.
function router() {
	ctrler="$PROJECT$reqPath/$reqMethod.sh"
	staticFile="$PROJECT$reqPath"

	if [ -f "$ctrler" ]; then
		log "${lcLGray}Executing the controller ${lcMagenta}$PROJECT${lcLCyan}$reqPath/${lcX}${lcLYellow}$reqMethod${lcMagenta}.sh"
		# This must be here in order for POST variables with spaces
		# to expand in templates correctly 
		IFS=$''
		source $ctrler

	elif [ -f "$staticFile" ]; then
		log "${lcLGray}Serving the static file ${lcMagenta}$PROJECT${lcLCyan}$reqPath"
		serveStatic $staticFile

	elif [ -d "$staticFile" ] && [ -f "$staticFile/index.html" ]; then
		log "${lcLGray}Serving the static file ${lcMagenta}$PROJECT${lcLCyan}$reqPath${lcMagenta}/index.html"
		serveStatic "$staticFile/index.html"

	else
		log "404 Not Found"
		resp.Status 404
		resp.Header "Content-Type" "text/html"
		resp.Body "<i>$reqPath</i> Was Not Found"

	fi
}

# Serves static files from file system.
# Tries to guess Content-Type from their extensions.
function serveStatic() {
	filePath=$1
	fileName=$(basename "$filePath")
	fileExt="${fileName##*.}"
	fileSize=$(stat --printf="%s" "$filePath")

	resp.Status "200"

	# TODO: resolve ERR_CONTENT_LENGTH_MISMATCH before enabling this back
	# resp.Header "Content-Length" $fileSize

	case $fileExt in
		"js")
			resp.Header "Content-Type" "application/javascript"
		;;

		"css")
			resp.Header "Content-Type" "text/css"
		;;

		"html")
			resp.Header "Content-Type" "text/html"
		;;

		"jpg"|"jpeg")
			resp.Header "Content-Type" "image/jpeg"
		;;

		"png")
			resp.Header "Content-Type" "image/png"
		;;

		*)
			resp.Header "Content-Type" "text/plain"
		;;
	esac

	resp.File $filePath
}