let blinkIntervalID;

function blinkTheBlinks() {
	unblinkTheBlinks();
	var blinkShown = true;
	blinkIntervalID = setInterval(() => {
		blinkShown=!blinkShown;
		document.body.parentElement.className = blinkShown ? "" : "noblink";
	}, 300)
}

function unblinkTheBlinks() {
	blinkIntervalID && clearInterval(blinkIntervalID)
}

function request(method, url, data, cb) {
	let req = new XMLHttpRequest;
	req.open(method, url, true)

	if (method === 'POST') {
		req.setRequestHeader('Content-type', 'application/json');
	}

	req.onreadystatechange = function (e) {
		if (this.readyState === 4) {
			if (this.status == 200) {
				cb && cb(JSON.parse(this.response));
			} else {
				d = JSON.parse(this.response)
				if (d.message) {
					d.command && console.error(`Error at ${d.command}`);
					console.error(d.message);
				} else {
					console.error(d);
				}
			}
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

let UPLOAD_ID=1

function submitForm(formID, url, cb) {
	(function(UID) {
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
				let newCode = this.responseText.substr(lastReceived);
				lastReceived = this.responseText.length;
				eval(newCode);
				cb(bwf.get(UID));
			}
		};

		req.upload.addEventListener("progress", (e) => {
			console.log("Progress is ", e);
		}, false);

		req.open('POST', url, true);
		req.setRequestHeader("X-Bwf-Upload-ID", UID)
		req.send(fd);
	})(`upl-${formID}-${UPLOAD_ID++}`)
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
	
	get: function(vn) {
		return bwf.valueStash[vn];
	}
};

function $(id) {
	return document.getElementById(id);
}

function id(eid) {
	return $(eid);
}

function requestComments() {
	request('GET', `/api/comments?image=${imageID}`, undefined, (cmnts) => {
		for (let c of cmnts) {
			addComment(c);
		}
	});
}

function addComment(cmnt) {
	let eP = document.createElement('p');
	eP.innerHTML = `~<em>#</em> ${cmnt.message.replace(/\n/gi, "<br>")}<blink>_</blink>`;
	id('comments-list').appendChild(eP);
}

function submitComment(imageID, message) {
	request('POST', '/api/comments', {
		imageID: imageID,
		message: message,
	});

	addComment({message: message});
}
