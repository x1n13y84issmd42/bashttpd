function blinkTheBlinks() {
	var blinkShown = true;
	setInterval(() => {
		blinkShown=!blinkShown;
		var blinks = document.getElementsByTagName("blink");
		for (let bl of blinks) {
			bl.style.display=blinkShown ? "inline" : "none";
		}
	}, 300)
}

function request(method, url, data, cb) {
	let req = new XMLHttpRequest;
	req.open(method, url, true)

	if (method === 'POST') {
		req.setRequestHeader('Content-type', 'application/json');
	}

	req.onreadystatechange = function (e) {
		if (this.readyState === 4) {
			cb(JSON.parse(this.response));
		}
	};

	req.send(data ? JSON.stringify(data) : undefined);
}

function requestVisits() {
	request("GET", "/api/visits", undefined, (resp) => {
		document.getElementById('visits').innerHTML = resp.visits + "-ish";

		let bv = document.getElementById('visits-big');
		let val = "[" + resp.visits + "]";
		bv.innerHTML = val;
		bv.className = bv.className + " w" + val.length;
	});
}