# Default value, override it in the .env file
LOG_VERBOSITY=1

# A pinch of syntatic sugar for declaring and initializing variables
function var {
	printf -v $1 "%s" "$2"
}

# Outputs to the host's stderr
function log {
	[[ $LOG_VERBOSITY -ge 1 ]] && printf "$@\n" | tr -d '\r' >&2
}

# Verbose logging
function logg {
	[[ $LOG_VERBOSITY -ge 2 ]] && printf "$@\n" | tr -d '\r' >&2
}

# Even more verbose logging
function loggg {
	[[ $LOG_VERBOSITY -ge 3 ]] && printf "$@\n" | tr -d '\r' >&2
}

# Like `return` in other languages, capture it with $()
function yield {
	echo -En $1
}

# Taken from https://gist.github.com/cdown/1163649#file-gistfile1-sh
function urldecode {
    local plussless="${1//+/ }"
    printf '%b' "${plussless//%/\\x}"
}

# Taken for granted from https://gist.github.com/cdown/1163649#gistcomment-1256298
function urlencode() {
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
    *) printf "$c" | xxd -p -c1 | while read x;do printf "%%%s" "$x";done
  esac
done
}
