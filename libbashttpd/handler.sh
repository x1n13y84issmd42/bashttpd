#!/bin/bash

source libbashttpd/utility.sh
source libbashttpd/request.sh
source libbashttpd/router.sh
source libbashttpd/bwf.sh

[[ -f .env ]] && source .env

PROJECT=$1

[[ -f $PROJECT/.env ]] && source $PROJECT/.env

readHeaders
normalizeHeaders
readBody

router

logg "Fin."