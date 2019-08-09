respStatus 200

local EXT=".bin"
local fCT=$(reqFileContentType theFileILike)

case $fCT in
	"image/jpeg")
		EXT="jpg"
	;;

	"image/png")
		EXT="png"
	;;

	"image/gif")
		EXT="gif"
	;;
esac

local fTmp=$(reqFile theFileILike)
local fDest=$(mktemp $PROJECT/storage/XXXXXXXX.$EXT)
mv $fTmp $fDest >&2

declare -A RESP=(
	[name]=$(reqData name)
	[age]=$(reqData age)
	[tpmFilename]=fName
	[srcFilename]=$(reqFileName theFileILike)
	[URL]="localhost:8080/$fDest"
	[isItReallyHappeningInBash]=true
)

respJSON RESP untyped