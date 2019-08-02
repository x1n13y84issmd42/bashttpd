name=$(reqData name)
age=$(reqData age)
tpmFilename=$(reqFile theFileILike)
srcFilename=$(reqFileName theFileILike)

# name=$(urlencode $name)

respStatus 200
respHeader "Content-Type" "application/json"

respBody "{\"name\":\"$name\", \"age\":\"$age\", \"srcFN\":\"$srcFilename\", \"tmpFN\": \"$tpmFilename\"}"
