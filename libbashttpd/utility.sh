# A syntatic sugar for declaring and initializing variables
function var {
	printf -v $1 "$2"
}

# Outputs to the host's stderr
function log {
	echo $@ >&2
}

# Like `return` in other languages, capture it with $()
function yield {
	echo -En $1
}
