req.Query image imageID

# Add an image=XXXX query string parameter to see comments for a specific image.
if [[ ! -z $imageID ]]; then
	mysql.Select image_comments "imageID=\"$imageID\"" ROWS
else
	mysql.All image_comments ROWS
fi

mysql.foreach do
	mysql.row
	RESP+=("$(JSON.EncodeObject row untyped)")
done

resp.Status 200
resp.JSON RESP