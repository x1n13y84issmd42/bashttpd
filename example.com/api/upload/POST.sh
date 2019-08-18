local EXT="bin"
local fCT=$(reqFileContentType aPicture)

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

	"image/x-icon")
		EXT="ico"
	;;

	*)
		log "Impossible file Content-Type: $fCT"
	;;
esac

local fTmp=$(reqFile aPicture)
local fDest=$(mktemp $PROJECT/$GALLERY_STORAGE/XXXXXXXX.$EXT)
mv $fTmp $fDest

declare -A RESP=(
	[tpmFilename]=$fTmp
	[srcFilename]=$(reqFileName aPicture)
	[URL]="http://${fDest//$PROJECT/localhost:8080}"
	[isItReallyHappeningInBash]=true
)

respStatus 200
respJSON RESP untyped