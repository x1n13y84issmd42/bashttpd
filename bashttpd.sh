#!/bin/bash

source libbashttpd/utility.sh
source libbashttpd/bwf.sh

log "Bashttpd 0.9.1"

[[ -f .env ]] && log "Loading .env" && source .env

project.Load $1

mysql.Install

function maybe_exit {
	if [ $1 -gt 0 ]; then
		log "Exited with $1"
		log "It was nice having you here. Come back one day."
		exit 0
	fi
}

function run.netcat {
	log "Using ${lcR}${lcLYellow}netcat${lcX} transport ${lcLRed}(not recommended, consider switching to ${lcbgLRed}${lcWhite}socat${lcX}${lcLRed})."
	while true; do
		netcat -l -k -p $PORT -c "./libbashttpd/handler.sh $1"
		maybe_exit $?
	done
}

function run.socat {
	log "Using ${lcR}${lcLGreen}socat${lcX} transport."
	socat TCP-LISTEN:$PORT,fork,reuseaddr EXEC:"./libbashttpd/handler.sh $1"
	maybe_exit $?
}

case $2 in
	'socat')
		sys.Installed socat && run.socat $1 || log "${lcbgLRed}${lcWhite}socat is not installed. Aborting."
	;;

	'netcat')
		sys.Installed netcat && run.netcat $1 || log "${lcbgLRed}${lcWhite}netcat is not installed. Aborting."
	;;

	*)
		if sys.Installed socat; then
			run.socat $1;
		elif sys.Installed netcat; then
			run.netcat $1;
		else
			log "${lcbgLRed}${lcWhite}Either socat or netcat is needed to handle connections, but none is installed. Aborting."
			exit 255
		fi
	;;
esac
