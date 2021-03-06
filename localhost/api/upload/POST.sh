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
	[name]=${fDest##*/}
	[tpmFilename]=$fTmp
	[srcFilename]=$(req.FileName aPicture)
	[URL]=$(project.URL ${fDest//$PROJECT\/})
	[isItReallyHappeningInBash]=true
)

resp.Status 200
resp.JSON RESP untyped