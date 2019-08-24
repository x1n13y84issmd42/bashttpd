local EXT="bin"
local fCT=$(req.FileContentType aPicture)

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

local fTmp=$(req.File aPicture)
local fDest=$(mktemp $PROJECT/$GALLERY_STORAGE/XXXXXXXX.$EXT)
mv $fTmp $fDest

declare -A RESP=(
	[tpmFilename]=$fTmp
	[srcFilename]=$(req.FileName aPicture)
	[URL]="http://${fDest//$PROJECT/localhost:8080}"
	[isItReallyHappeningInBash]=true
)

resp.Status 200
resp.JSON RESP untyped