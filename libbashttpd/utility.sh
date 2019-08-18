# Default value, override it in the .env file
LOG_VERBOSITY=1

# A pinch of syntatic sugar for declaring and initializing variables
function var {
	printf -v $1 "%s" "$2"
}

# Outputs to the host's stderr
function log {
	[[ $LOG_VERBOSITY -ge 1 ]] && printf "%s " $@ >&2 && echo "" >&2
	return 0
}

# Verbose logging
function logg {
	[[ $LOG_VERBOSITY -ge 2 ]] && log $@
}

# Even more verbose logging
function loggg {
	[[ $LOG_VERBOSITY -ge 3 ]] && log $@
}

# Slightly annoying logging
function logggg {
	[[ $LOG_VERBOSITY -ge 4 ]] && log $@
}

# Absolutely annoying chatter
function loggggg {
	[[ $LOG_VERBOSITY -ge 5 ]] && log $@
}

# Like `return` in other languages, capture it with $()
function yield {
	echo -En "$@"
}

# Taken from https://gist.github.com/cdown/1163649#file-gistfile1-sh
function urldecode {
    local plussless="${1//+/ }"
    printf '%b' "${plussless//%/\\x}"
}

# Taken from https://gist.github.com/cdown/1163649#gistcomment-1256298
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

# Joins it's arguments into a string.
# Delimiter goes as a first argument.
function array.join {
	local d=$1;
	shift

	res=""
	
	for a in ${@}; do
		res="$res$d$a"
	done

	echo ${res:${#d}}
}

# Tries to figure out the type of given variable.
# Takes a name of a variable, not the variable itself.
# Usage:
#	userName="John"
#	listOfThings=(1 2 33 444)
#	declare -A mapOfThings=([first]=1 [other]=2 [nextAfterOther]=33 [plenty]=444)
#	boolFlagValue=true
#	userAge=234
#	reflection.Type userName # outputs "STRING"
#	reflection.Type listOfThings # outputs "ARRAY"
#	reflection.Type mapOfThings # outputs "MAP"
#	reflection.Type boolFlagValue # outputs "BOOLEAN"
#	reflection.Type userAge # outputs "NUMBER"
function reflection.Type {
	decl=$(declare -p $1)
	mode=${decl:8:2}

	val=$(eval echo \$${1})

	case $mode in
		"-a")
			echo "ARRAY"
		;;

		"-A")
			echo "MAP"
		;;

		*)
			if [[ $val == "true" || $val == "false" ]]; then
				echo "BOOLEAN"
			elif [[ $val =~ ^[[:digit:]]+$ ]]; then
				echo "NUMBER"
			else
				echo "STRING"
			fi
		;;
	esac
}

declare -a IFS_backup_stack

# Changes the IFS variable while backing it up and automatically restoring.
# To set a new IFS: sys.IFS $'\r'
# To reset IFS to it's original value: sys.IFS
function sys.IFS {
	if [[ -z ${1+x} ]]; then
		# Resetting
		IFS_backup=${IFS_backup_stack[${#IFS_backup_stack[@]}-1]}
		if ! [[ -z $IFS_backup ]]; then
			IFS=$IFS_backup
			unset IFS_backup_stack[${#IFS_backup_stack[@]}-1]
		fi
	else
		# Setting a new value
		echo "IFS set to $1"
		IFS_backup_stack+=("$IFS")
		IFS=$1
	fi
}