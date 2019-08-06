_IFS=$IFS
# IFS=$'\r'
IFS=$''
LANG=C
LC_ALL=C

CL=0

# Reading body, 1 char at a time
# Regular read can't get the last line because of missing newline on this Content-Type
if [ -z ${CONTENT_LENGTH+x} ]; then
	:
else
	while [ $CL -lt $CONTENT_LENGTH ]; do
		read -r -d '' -n1 CHAR
		let CL=CL+1
		BODY="$BODY$CHAR"
		local lochar=$(echo -n $CHAR | tr '\n' '\\')
		local charhex=$(echo -en "$CHAR" | xxd -ps)
		log "**           DONE READIN   ${#CHAR}/$CL		$charhex ($lochar)      **"

		if [[ $BODY =~ "$CONTENT_BOUNDARY"$ ]]; then
			log " * * * * * * BOUNDARY * * * * * * "
		fi
	done;

		log "___________________DOOOOOOOOOOONE______________________________________"

		SEPAR="----------"
		FIELDS=(${BODY//$SEPAR/ })
		for FIELD in "${FIELDS[@]}"; do
			log "FIELD:"
			log "________________________________________________________________________________________"
			log "$FIELD"

			echo -En "$FIELD" | xxd >&2
			# log $fx
		done	

	# Debug dump
	[[ ! -z $DEBUG_DUMP_BODY ]] && echo -n "$BODY" > $DEBUG_DUMP_BODY
fi

# An implementation of reqData.
function reqDataImpl {
	vn="DATA_$1"
	yield ${!vn}
}

IFS=$_IFS

local char=$CHAR

		# log "?? ?? ?? ?? ??"
		# printf "%s\n" $CHAR | tr -d '\r' >&2
		# FIELDS=(${BODY//$CONTENT_BOUNDARY/ })
		# for FIELD in "${FIELDS[@]}"; do
		# 	# log "FIELD:"
		# 	# log "________________________________________________________________________________________"
		# 	# log "$FIELD"

		# 	local fx=$(echo -En "$FIELD" | xxd)
		# 	# log $fx
		# done	
		

		# printf "%s\n" $char >&2

		# local charhex=$(echo -en "$CHAR" | xxd -ps)
		# printf "%010d: %s    %s\n" $CL $charhex $char >&2