# Default value, override it in the .env file
LOG_VERBOSITY=1

# A pinch of syntatic sugar for declaring and initializing variables
function var {
	printf -v $1 "%s" "$2"
}

# Outputs to the host's stderr
function log {
	_IFS=$IFS
	IFS=''
	[[ $LOG_VERBOSITY -ge 1 ]] && printf "%s " $@ >&2 && echo "" >&2
	IFS=$_IFS
	return 0
}

# Verbose logging
function logg {
	[[ $LOG_VERBOSITY -ge 2 ]] && log $@
	return 0
}

# Even more verbose logging
function loggg {
	[[ $LOG_VERBOSITY -ge 3 ]] && log $@
	return 0
}

# Slightly annoying logging
function logggg {
	[[ $LOG_VERBOSITY -ge 4 ]] && log $@
	return 0
}

# Absolutely annoying chatter
function loggggg {
	[[ $LOG_VERBOSITY -ge 5 ]] && log $@
	return 0
}

function error {
	echo -En "$1"
}

# Like `return` in other languages, capture it with $()
function yield {
	if [[ -z $2 ]]; then
		echo -En "$1"
	else
		var $2 "$1"
		eval "${2}=\"$1\""
	fi
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

# Declares a copy of an associative array by its provided name.
# Context:
#	$1 must be a name of an associative array variable.
#	Creates a local variable $E which is a copy of $the array referenced by $1.
alias array.getbyref='e="$( declare -p ${1} )"; eval "declare -A E=${e#*=}"'

# Declares a copy of an associative array by its provided name, gets the name from $2.
alias array.getbyref2='e="$( declare -p ${2} )"; eval "declare -A E=${e#*=}"'

# Iterates over the array created by array.getbyref.
# Context:
#	array.getbyref must be called prior to this.
#	the do...done block must be supplied by the caller.
alias array.foreach='for key in "${!E[@]}"'

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
		IFS_backup_stack+=("$IFS")
		IFS=$1
	fi
}

# Initilizes function arguments in reversed order, so $#-th argument becomes $_0, $#-1 becomes $_1 and so on.
# Context:
#	Used within a function.
#	Creates local variables $_0, $_1 ...
alias fn.arguments='local _0; local _1; local _2; eval "_0=\$$(($#-0)); _1=\$$(($#-1)); _2=\$$(($#-2))"'
