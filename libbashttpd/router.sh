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
		log "${lcLGray}Executing the controller ${lcBlue}$PROJECT${lcLCyan}$reqPath/${lcX}${lcLYellow}$reqMethod${lcBlue}.sh"
		# This must be here in order for POST variables with spaces
		# to expand in templates correctly 
		IFS=$''
		source $ctrler

	elif [ -f "$staticFile" ] && safeToServeStatically "$staticFile"; then
		log "${lcLGray}Serving the static file ${lcBlue}$PROJECT${lcLCyan}$reqPath"
		serveStatic $staticFile

	elif [ -d "$staticFile" ] && [ -f "$staticFile/index.html" ]; then
		log "${lcLGray}Serving the static file ${lcBlue}$PROJECT${lcLCyan}$reqPath${lcBlue}/index.html"
		serveStatic "$staticFile/index.html"

	else
		log "404 Not Found"
		resp.Status 404
		resp.Header "Content-Type" "text/html"
		resp.Body "<i>$reqPath</i> Was Not Found"

	fi
}

# Checks the request path and a path BWF has chosen to serve
# statically for various criterias that may make serving impossible.
# Examples are dotfiles & handler scripts.
#	Arguments:
#		$1: the path BWF decided to serve.
function safeToServeStatically {
	# Checking the path for dotfiles
	if [[ $1 =~ \/\. && $SERVE_DOTFILES == 0 ]]; then
		logg "${lcLRed}Requests to dotfiles are forbidden for security reasons."
		return 255
	fi

	# Checking if the path ends up with a handler script
	if [[ $1 =~ (GET|POST|PUT|DELETE|OPTIONS).sh$ && $SERVE_HANDLER_SCRIPTS == 0 ]]; then
		logg "${lcLRed}Requests to handler scripts are forbidden for security reasons."
		return 255
	fi

	return 0
}

# Serves static files from file system.
# Tries to guess Content-Type from their extensions.
function serveStatic() {
	filePath=$1
	fileName=$(basename "$filePath")
	fileExt="${fileName##*.}"
	fileMIMEType=$(file -b --mime-type "$filePath")
	fileSize=$(stat --printf="%s" "$filePath")

	resp.Status "200"

	resp.Header "Content-Length" $fileSize

	case $fileExt in
		# Somehow `file --mime-type` recognizes css files as text/x-asm
		"css")
			resp.Header "Content-Type" "text/css"
		;;

		*)
			resp.Header "Content-Type" "$fileMIMEType"
		;;
	esac

	resp.File $filePath
}