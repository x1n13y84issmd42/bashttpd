req.Data imageID imageID
req.Data message message

declare -A COMMENT=(
	[imageID]=$imageID
	[message]=$message
)

mysql.Insert image_comments COMMENT ID
declare -A RESP=([commentID]=$ID)

resp.Status 201
resp.JSON RESP

log "The comment ${lcEm}\"${message}\"${lcX} saved as ${ID}."
