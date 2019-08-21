ID=$(reqQuery ID)
ID=${ID//\//}
path=$(realpath "$PROJECT/storage/images/$ID")
log "The image path is $path"

if [[ -f $path ]]; then
	imageURL="http://localhost:8080/$GALLERY_STORAGE/${ID}"
	respStatus 200
	respHeader "Content-Type" "text/html"
	respTemplateFile "/assets/tpl/image.html"
else
	respStatus 404
	respHeader "Content-Type" "text/html"
	respTemplateFile "/assets/tpl/404.html"
fi