function router() {
	ctrler="$PROJECT$reqPath/$reqMethod.sh"

	log "Looking for a controller $ctrler"

	if [ -f "$ctrler" ]; then
		log "Found a controller"
		$ctrler
	else
		log "404 Not Found"
	fi
}
