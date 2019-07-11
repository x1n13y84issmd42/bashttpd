var blinkShown=true;

function blinkTheBlinks() {
	setInterval(() => {
		blinkShown=!blinkShown;
		var blinks = document.getElementsByTagName("blink");
		for (let bl of blinks) {
			bl.style.display=blinkShown ? "inline" : "none";
		}
	}, 300)
}