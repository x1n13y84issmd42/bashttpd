#!/bin/bash

respStatus 200
respHeader "Content-Type" "application/json"

lsOut=$(ls -lA --time-style=long-iso $PROJECT/assets)
IFS=$'\n'
read -r -d '\n' -a FILES <<< $lsOut

IFS=$' '

RESP_FILES=()

for FILE in "${FILES[@]}"; do
	read -r -a LINE <<< $FILE

	fName=${LINE[7]}
	fSize=${LINE[4]}
	fDate="${LINE[5]} ${LINE[6]}"

	if ! [[ -z $fName || -z $fSize || -z $fDate ]]; then
		fResp="{\"name\":\"$fName\",\"size\":\"$fSize\",\"modifiedAt\":\"$fDate\"}"
		RESP_FILES+=("$fResp")
	fi
done

body=$(array.join ", " ${RESP_FILES[@]})
respBody "[$body]"
