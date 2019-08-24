ID=$(req.Query ID)
ID=${ID//\//}
path=$(realpath "$PROJECT/storage/images/$ID")
log "The image path is $path"

if [[ -f $path ]]; then
	imageURL="http://localhost:8080/$GALLERY_STORAGE/${ID}"
	resp.Status 200
	resp.Header "Content-Type" "text/html"
	resp.TemplateFile "/assets/tpl/image.html"
else
	resp.Status 404
	resp.Header "Content-Type" "text/html"
	resp.TemplateFile "/assets/tpl/404.html"
fi