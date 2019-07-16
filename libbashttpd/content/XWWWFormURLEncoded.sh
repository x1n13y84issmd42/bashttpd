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
fi

IFS_backup="$IFS"
IFS='&'

read -r -a FIELDS <<< "$BODY"
for FIELD in "${FIELDS[@]}"; do
	fieldName=$(echo -En "$FIELD" | cut -d "=" -f 1)
	fieldValue=$(echo -En "$FIELD" | cut -d "=" -f 2)

	var "DATA_$fieldName" "$fieldValue"
done	

IFS="$IFS_backup"

# An implementation of reqData.
function reqDataImpl {
	vn="DATA_$1"
	yield ${!vn}
}
