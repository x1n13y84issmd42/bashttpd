#!/bin/bash

source libbashttpd/utility.sh
source libbashttpd/request.sh
source libbashttpd/router.sh
source libbashttpd/bwf.sh

[[ -f .env ]] && source .env

PROJECT=$1

readHeaders
normalizeHeaders

logg "-- Content Type is $CONTENT_TYPE"
logg "-- Content Boundary is $CONTENT_BOUNDARY"
logg "-- Content Length is $CONTENT_LENGTH"

readBody

router

logg "Fin."
log ""