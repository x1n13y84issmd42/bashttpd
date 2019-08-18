ROWS=$(mysql.Select image_comments)

mysql.foreach do
	mysql.row
	RESP+=("$(JSON.EncodeObject row untyped)")
done

respStatus 200
respJSON RESP