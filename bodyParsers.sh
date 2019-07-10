# Outputs a single value from the request body.
# function reqData {

# }

function reqDataForm {

	fieldName=$1
	mode="searching"
	fieldValue=""

	BODYNL="$(echo $BODY | tr '\r' '@')"
	IFS_backup="$IFS"
	IFS='@'
	readarray BODYLINES <<< "$BODYNL"
	for LINE in $BODYLINES; do
		if [[ $LINE =~ Content-Disposition:form-data\;name=\"$fieldName\" ]]; then
			# log "Found $fieldName field ($LINE)"
			mode="accumulating"
			continue
		fi

		if [ $mode = "accumulating" ]; then
			if [[ $LINE =~ $CONTENT_BOUNDARY ]]; then
				# log "Found the content boundary"
				break
			else
				fieldValue="$fieldValue$LINE"
			fi
		fi
	done
	IFS="$IFS_backup"

	echo "$fieldValue"
}

function reqDataJSON {
	log "Support for JSON is not implemented yet. Check back soon."
}
