imageID=$(reqQuery image)

# Add an image=XXXX query string parameter to see comments for a specific image.
if [[ ! -z $imageID ]]; then
	ROWS=$(mysql.Select image_comments "imageID=\"$imageID\"")
else
	ROWS=$(mysql.Select image_comments)
fi

mysql.foreach do
	mysql.row
	RESP+=("$(JSON.EncodeObject row untyped)")
done

respStatus 200
respJSON RESP