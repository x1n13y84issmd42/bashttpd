reqQuery image imageID

# Add an image=XXXX query string parameter to see comments for a specific image.
if [[ ! -z $imageID ]]; then
	mysql.Select image_comments "imageID=\"$imageID\"" ROWS
else
	mysql.Select image_comments ROWS
fi

mysql.foreach do
	mysql.row
	RESP+=("$(JSON.EncodeObject row untyped)")
done

respStatus 200
respJSON RESP