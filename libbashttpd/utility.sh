LOG_VERBOSITY=1

# A syntatic sugar for declaring and initializing variables
function var {
	printf -v $1 "$2"
}

# Outputs to the host's stderr
function log {
	[[ $LOG_VERBOSITY -ge 1 ]] && echo $@ >&2
}

function logg {
	[[ $LOG_VERBOSITY -ge 2 ]] && echo $@ >&2
}

function loggg {
	[[ $LOG_VERBOSITY -ge 3 ]] && echo $@ >&2
}

# Like `return` in other languages, capture it with $()
function yield {
	echo -En $1
}
