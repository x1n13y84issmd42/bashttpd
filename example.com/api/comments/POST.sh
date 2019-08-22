declare -A COMMENT=(
	[imageID]=$(reqData "imageID")
	[message]=$(reqData "message")
)

mysql.Insert image_comments COMMENT ID
declare -A RESP=([commentID]=$ID)

respStatus 201
respJSON RESP
