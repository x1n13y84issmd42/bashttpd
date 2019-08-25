#!/bin/bash

source libbashttpd/utility.sh
source libbashttpd/request.sh
source libbashttpd/router.sh
source libbashttpd/bwf.sh

[[ -f .env ]] && source .env

project.Load $1

readHeaders
normalizeHeaders
readBody

router

logg "Fin."