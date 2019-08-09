# Executing ls
lsOut=$(ls -lA --time-style=long-iso $PROJECT/assets)

# Reading it's output, separated by \n
IFS=$'\n'
read -r -d '' -a FILES <<< $lsOut

for FILE in "${FILES[@]}"; do
	# Reading a single line of output, separated by whitespace
	IFS=$' '
	read -r -a LINE <<< $FILE
	
	if ! [[ -z ${LINE[7]} || -z ${LINE[4]} ]]; then
		declare -A fdata=(
			[name]="${LINE[7]}"
			[size]="${LINE[4]}"
			[modifiedAt]="${LINE[5]} ${LINE[6]}"
		)
		# Encoding an object and saving it as a string to RESP_FILES
		IFS=''
		RESP_FILES+=("$(JSON.EncodeObject fdata untyped)")
	fi
done

respStatus 200
respJSON RESP_FILES