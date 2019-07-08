function router() {
	ctrler="$PROJECT$reqPath/$reqMethod.sh"

	log "Looking for a controller $ctrler"

	if [ -f "$ctrler" ]; then
		log "Found a controller"
		$ctrler
	else
		log "404 Not Found"
		respStatus 404
		respHeader "Content-Type" "text/html"
		respBody "<i>$reqPath</i> Was Not Found"
	fi
}
