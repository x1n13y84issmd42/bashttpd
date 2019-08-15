function blinkTheBlinks() {
	var blinkShown = true;
	setInterval(() => {
		blinkShown=!blinkShown;
		document.body.parentElement.className = blinkShown ? "" : "noblink";
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
		bv.className = "w" + val.length;
	});
}

function submitForm(formID, url, cb) {
	let form = document.getElementById(formID);
	let fd = new FormData(form);
	let req = new XMLHttpRequest();

	let lastReceived = 0;
	req.onreadystatechange = function (e) {
		if (this.readyState === 3) {
			let newCode = this.responseText.substr(lastReceived);
			lastReceived = this.responseText.length;
			eval(newCode);
		} else if (this.readyState === 4) {
			cb(bwf.get("aPictureResponse"));
		}
	};

	req.upload.addEventListener("progress", (e) => {
		console.log("Progress is ", e);
	}, false);

	req.open('POST', url, true);
	req.send(fd);
}

function progressBar(id, p) {
	document.getElementById(id).childNodes[0].style.width = `${p}%`;
}

let bwf = {
	renderUploadProgress: function($l, $cl) {
		progressBar('aPictureProgress', $l / $cl * 100);
	},

	valueStash: {},

	set: function(vn, v) {
		bwf.valueStash[vn] = v;
	},
	
	get: function(vn, v) {
		return bwf.valueStash[vn];
	}
};

function $(id) {
	return document.getElementById(id);
}