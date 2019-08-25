# Executing ls
lsOut=$(ls -lA --time-style=long-iso $PROJECT/$GALLERY_STORAGE)
readarray -t LINES <<< $lsOut

# Going through it's output
for LINE in "${LINES[@]}"; do
	# Splitting the line by whitespace.
	IFS=$' '
	FILE=($LINE)
	
	# If there are size & name columns in place
	if ! [[ -z ${FILE[7]} || -z ${FILE[4]} ]]; then
		declare -A fdata=(
			[name]="${FILE[7]}"
			[URL]=$(project.URL $GALLERY_STORAGE ${FILE[7]})
			[size]="${FILE[4]}"
			[modifiedAt]="${FILE[5]} ${FILE[6]}"
		)
		# Encoding an object and appending it as a string to RESP_FILES
		IFS=''
		RESP_FILES+=("$(JSON.EncodeObject fdata untyped)")
		log "File ${fdata[name]} added"
	fi
done

resp.Status 200
resp.JSON RESP_FILES