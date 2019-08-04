_IFS=$IFS
IFS=$'\r'
CL=0

# Reading body, 1 char at a time
# Regular read can't get the last line because of missing newline on this Content-Type
if [ -z ${CONTENT_LENGTH+x} ]; then
	:
else
	while [ $CL -lt $CONTENT_LENGTH ]; do
		read -n1 -r CHAR
		BODY="$BODY$CHAR"
		let CL=CL+1
	done;

	# Debug dump
	[[ ! -z $DEBUG_DUMP_BODY ]] && echo -n "$BODY" > $DEBUG_DUMP_BODY
fi

# An implementation of reqData.
function reqDataImpl {
	yield $(echo -nE "$BODY" | jq -r $1)
}

IFS=$_IFS