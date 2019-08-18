declare -A COMMENT=(
	[imageID]=$(reqData "imageID")
	[message]=$(reqData "message")
)

ID=$(mysql.Insert image_comments COMMENT)
declare -A RESP=([commentID]=$ID)

respStatus 201
respJSON RESP
