declare -A COMMENT=(
	[imageID]=$(req.Data "imageID")
	[message]=$(req.Data "message")
)

mysql.Insert image_comments COMMENT ID
declare -A RESP=([commentID]=$ID)

resp.Status 201
resp.JSON RESP
