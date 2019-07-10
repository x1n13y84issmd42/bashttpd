function router() {
	ctrler="$PROJECT$reqPath/$reqMethod.sh"
	staticFile="$PROJECT$reqPath"

	if [ -f "$ctrler" ]; then
		log "Executing the controller $ctrler"
		source $ctrler

	elif [ -f "$staticFile" ]; then
		log "Serving the static file $staticFile"
		serveStatic $staticFile

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
	respHeader "Content-Length" $fileSize

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

		*)
			respHeader "Content-Type" "text/plain"
		;;
	esac

	respFile $filePath
}