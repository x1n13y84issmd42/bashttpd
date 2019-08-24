CL=0

# Reading body, 1 char at a time
# Regular read can't get the last line because of missing newline on this Content-Type
if [ -z ${CONTENT_LENGTH+x} ]; then
	:
else
	while [ $CL -lt $CONTENT_LENGTH ]; do
		read -n1 CHAR
		BODY="$BODY$CHAR"
		let CL=CL+1
	done;

	# Debug dump
	[[ ! -z $DEBUG_DUMP_BODY ]] && echo -nE $BODY > $DEBUG_DUMP_BODY
fi

IFS_backup="$IFS"
IFS='&'

read -r -a FIELDS <<< "$BODY"
for FIELD in "${FIELDS[@]}"; do
	fieldName=$(echo -En "$FIELD" | cut -d "=" -f 1)
	fieldValue=$(echo -En "$FIELD" | cut -d "=" -f 2)

	fieldValue=$(urldecode $fieldValue)
	var "DATA_$fieldName" "$fieldValue"
done

IFS="$IFS_backup"

# An implementation of req.Data.
function req.DataImpl {
	vn="DATA_$1"
	yield ${!vn}
}
