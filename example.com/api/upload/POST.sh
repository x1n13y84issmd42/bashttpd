respStatus 200

declare -A RESP=(
	[name]=$(reqData name)
	[age]=$(reqData age)
	[tpmFilename]=$(reqFile theFileILike)
	[srcFilename]=$(reqFileName theFileILike)
)

respJSON RESP