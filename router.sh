function router() {
	ctrler="$PROJECT$reqPath/$reqMethod.sh"
	staticFile="$PROJECT$reqPath"

	if [ -f "$ctrler" ]; then
		log "Executing the controller $ctrler"
		source $ctrler

	elif [ -f "$staticFile" ]; then
		log "Serving the static file $staticFile"
		serveStatic $staticFile

	elif [ -d "$staticFile" ] && [ -f "$staticFile/index.html" ]; then
		log "Serving the index.html of $staticFile"
		serveStatic "$staticFile/index.html"

	else
		log "404 Not Found"
		respStatus 404
		respHeader "Content-Type" "text/html"
		respBody "<i>$reqPath</i> Was Not Found"

	fi
}

function serveStatic() {
	filePath=$1
	fileName=$(basename "$filePath")
	fileExt="${fileName##*.}"
	fileSize=$(stat --printf="%s" "$filePath")

	respStatus "200"

	# TODO: resolve ERR_CONTENT_LENGTH_MISMATCH before enabling this back
	# respHeader "Content-Length" $fileSize

	case $fileExt in
		"js")
			respHeader "Content-Type" "application/javascript"
		;;

		"css")
			respHeader "Content-Type" "text/css"
		;;

		"html")
			respHeader "Content-Type" "text/html"
		;;

		"jpg"|"jpeg")
			respHeader "Content-Type" "image/jpeg"
		;;

		"png")
			respHeader "Content-Type" "image/png"
		;;

		*)
			respHeader "Content-Type" "text/plain"
		;;
	esac

	respFile $filePath
}