# Outputs a single value from the request body.
function reqData {
	case $CONTENT_TYPE in
		"multipart/form-data")
			reqDataForm $1
		;;

		"application/json")
			reqDataJSON $1
		;;

		*)
			echo "$CONTENT_TYPE is not supported yet."
		;;
	esac
}

function reqDataForm {
	fieldName=$1
	mode="searching"

	# TODO: figure out the right way to parse the body
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
	echo "Support for JSON is not implemented yet. Check back soon."
}
