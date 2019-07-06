# Bashttpd Web Framework

# Output to the host's stdout
function log {
	echo $1 >&2
}

# Sends an HTTP response status code
function respStatus {
	echo "HTTP/1.1 $1"
}

# Sends an HTTP response header
function respHeader {
	echo "$1: $2"
}

# Sends an HTTP response body
function respBody {
	echo ""
	echo $1
}