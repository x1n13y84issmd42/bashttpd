CREATE TABLE image_comments (
	id INT(11) NOT NULL AUTO_INCREMENT,
	imageID VARCHAR(50) NOT NULL,
	message VARCHAR(5000) NOT NULL,
	date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (id)
)
COLLATE='utf8_general_ci'
ENGINE=InnoDB
AUTO_INCREMENT=38
;


INSERT INTO `image_comments` (`id`, `imageID`, `message`, `date`) VALUES (38, 'UXRf0oub.jpg', 'REST APIs are totally possible with BWF and it\'s support for MySQL and JSON data.', '2019-08-25 11:19:44');
INSERT INTO `image_comments` (`id`, `imageID`, `message`, `date`) VALUES (39, 'UXRf0oub.jpg', 'You can leave comments in the field below and they will be saved to the DB.', '2019-08-25 10:24:57');
