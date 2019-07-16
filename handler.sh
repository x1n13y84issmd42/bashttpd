#!/bin/bash

source libbashttpd/utility.sh
source libbashttpd/request.sh
source libbashttpd/router.sh
source bwf.sh

PROJECT=$1

readHeaders
normalizeHeaders

log "-- Content Type is $CONTENT_TYPE"
log "-- Content Boundary is $CONTENT_BOUNDARY"
log "-- Content Length is $CONTENT_LENGTH"

readBody

router
