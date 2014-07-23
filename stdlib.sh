# Copyright 2013,2014 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2
# $Header: systems-engineering/lang/bash/stdlib.sh,v 1.4.1 2014/07/23 17:51:48 stuart.shelton Exp $
# 
# stdlib.sh standardised shared functions...

# Only load stdlib once, and provide support for loading stdlib from bashrc to
# reduce startup times...
#
if [[ -z "${STDLIB_HAVE_STDLIB:-}" ]]; then


# Pull this file into external scripts as follows:
#
cat >/dev/null <<EOC
# --- CUT HERE ---
# stdlib.sh should be in /usr/local/lib/stdlib.sh, which can be found as
# follows by scripts located in /usr/local/{,s}bin/...
std_LIB="stdlib.sh"
for std_LIBPATH in \
	"." \
	"$( dirname "$( type -pf "${std_LIB}" 2>/dev/null )" )" \
	"$( readlink -e "$( dirname -- "${BASH_SOURCE:-${0:-.}}" )/../lib" )" \
	"/usr/local/lib" \
	 ${FPATH:+${FPATH//:/ }} \
	 ${PATH:+${PATH//:/ }}
do
	if [[ -r "${std_LIBPATH}/${std_LIB}" ]]; then
		break
	fi
done
[[ -r "${std_LIBPATH}/${std_LIB}" ]] && source "${std_LIBPATH}/${std_LIB}" || {
	echo >&2 "FATAL:  Unable to source ${std_LIB} functions"
	exit 1
}
# --- CUT HERE ---
EOC


# What API version are we exporting?
export  std_RELEASE="1.4" # Add std::parseargs
#export std_RELEASE="1.3" # Initial import
readonly std_RELEASE


declare std_DEBUG
# Standard usage is:
#
std_DEBUG="${DEBUG:-0}"

declare std_TRACE
# Standard usage is:
#
std_TRACE="${TRACE:-0}"
#
# ... and then include:
#
cat >/dev/null <<EOC
# --- CUT HERE ---
(( std_TRACE )) && set -o xtrace
# --- CUT HERE ---
EOC
#
# ... near the top of the calling script.

# If this is not overridden, then logging will be disabled:
#
declare std_LOGFILE="/dev/null"
#
# Note that std_LOGFILE may also be given the special value of "syslog" to use
# 'logger'(1) to send messages to local syslogd.

# All scripts should end with the lines:
#
cat >/dev/null <<EOC
# --- CUT HERE ---
function main() {
	...
} # main

main "${@:-}"

exit 0

# set vi: syntax=sh colorcolumn=80 foldmethod=marker:
# --- CUT HERE ---
EOC


#
# Externally set control-variables:
#
# STDLIB_WANT_ERRNO	- Load errno-like functions;
# STDLIB_WANT_MEMCACHED	- Load native memcached functions;
# STDLIB_API		- Specify the stdlib API to adhere to.
#
# Exported control-variables:
#
# STDLIB_HAVE_STDLIB	- Set once stdlib functions have been loaded;
# STDLIB_HAVE_BASH_4	- Set if interpreter is bash-4 or above;
# STDLIB_HAVE_ERRNO	- Set if errno functions have been initialised;
# STDLIB_HAVE_MEMCACHED	- Set if bash memcached interace is available.
#
# Externally referenced variables:
#
# std_USAGE		- Specify simple usage strings.  For more complex
# 			  requirements, instead override usage-message;
# std_ERRNO		- Return an additional error-indication from a
# 			  function.
#


###############################################################################
#
# stdlib.sh - Setup and standard functions
#
###############################################################################

# Throw an error if parameter-expansion occurs with an unset variable.
#
# Gentleman, start your debuggers ;)
#
set -u

# Try to impose sane handling of the '!' character...
#
set +o histexpand

# Use 'output' rather than 'echo' to clearly differentiate user-visible
# output from pipeline-intermediate commands.
#
function output() {
	[[ -n "${@:-}" ]] && echo -e "${@}"
} # output

# Use 'respond' rather than 'echo' to clearly differentiate function results
# from pipeline-intermediate commands.
#
function respond() {
	[[ -n "${@:-}" ]] && echo "${@}"
} # respond

# Use of aliases requires more investigation to ensure reliability.
#
## N.B.: Set this in order to have aliases interpreted by scripts...
##
##shopt -qs expand_aliases
##alias output='echo -e'
##alias respond='echo'


###############################################################################
#
# stdlib.sh - Standard functions and variables
#
###############################################################################

unalias cp >/dev/null 2>&1
unalias ls >/dev/null 2>&1
unalias mv >/dev/null 2>&1
unalias rm >/dev/null 2>&1

export std_PREFIX="${std_PREFIX:-/usr/local}"
export std_BINPATH="${std_PREFIX}/bin"
# N.B.: Earlier auto-discovered value for std_LIBPATH is replaced here:
export std_LIBPATH="${std_PREFIX}/lib"

# ${0} may equal '-bash' if invoked directly, in which case basename fails as
# it tries to interpret '-b ash'.
export NAME="$( basename -- "${0:-${std_LIB}}" )"

# Ensure a sane sorting order...
export LC_ALL="C"

# These values should make certain code much clearer...
export std_TAB='	'
export std_NL='
'

# We don't want to rely on $SHELL so, as an alternative, this should work - but
# is also a little bit scary...
#
declare -i STDLIB_HAVE_BASH_4=0

export STDLIB_HAVE_ERRNO=0
export STDLIB_HAVE_STDLIB=0
export STDLIB_HAVE_MEMCACHED=0

export std_ERRNO=0

declare -a __STDLIB_OWNED_FILES


###############################################################################
#
# stdlib.sh - Shell detection
#
###############################################################################

# N.B.: In general, we don't want to reference ${0} as it may be unreliable if
#       we're sourced from a script itself sourced from another script... but
#       in this case the ultimate parent does impose the interpreter.
#
function __STDLIB_oneshot_get_bash_version() {
	local parent="${0:-}"
	local int shell version

	# Please note - this function may have unintended consequences if
	# invoked from a script which has an interpreter which causes a
	# permanent state-change if executed with '--version' as a parameter.

	if [[ -z "${parent:-}" || "$( basename -- "${parent#-}" )" == "bash" ]]; then
		# If stdlib.sh is sourced directly, $0 will be 'bash' (or
		# another shell name, which should be listed in /etc/shells)
		#
		if [[ -n "${SHELL:-}" ]]; then
			shell="$( basename "${SHELL}" )"
		else
			shell="bash" # We'll assume...
		fi

	elif [[ -r "${parent}" ]]; then
		# Our interpreter should be some valid shell...
		int="$( head -n 1 "${parent}" )"
		int="$( sed 's|^#\! \?||' <<<"${int}" )"
		if [[ \
			"${int:0:4}" == "env " || \
			"${int:0:9}" == "/bin/env " || \
			"${int:0:13}" == "/usr/bin/env " \
		]]; then
			shell="$( cut -d' ' -f 2 <<<"${int}" )"
		else
			shell="$( cut -d' ' -f 1 <<<"${int}" )"
		fi

	else
		warn "Unknown interpretor"
	fi

	if [[ -n "${shell:-}" ]]; then
		shell="$( readlink -e "$( type -pf "${shell:-bash}" 2>/dev/null )" )"
		if [[ -n "${shell:-}" && -x "${shell}" ]]; then
			version="$( "${shell}" --version 2>&1 | head -n 1 )" || \
				die "Cannot determine version for" \
				    "interpreter '${shell}'"
			#if grep -q "^GNU bash, version " >/dev/null 2>&1 <<<"${version}"; then
			if echo "${version}" | grep -q "^GNU bash, version " >/dev/null 2>&1; then
				#if ! grep -q " version [0-3]" >/dev/null 2>&1 <<<"${version}"; then
				if ! echo "${version}" | grep -q " version [0-3]" >/dev/null 2>&1; then
					STDLIB_HAVE_BASH_4=1
				fi
				# N.B.: Don't abort if we can't determine our
				#     interpretor's capabilities - simply don't set
				#     STDLIB_HAVE_BASH_4.
				#
			#else
			#	die "Cannot determine version for interpreter '${BASH}' (from '${version}')"
			fi
		#else
		#	die "Cannot execute interpreter '${int}'"
		fi

		unset version shell int
	#else
	#	die "Cannot locate this script (tried '${0}')"
	fi

	export STDLIB_HAVE_BASH_4

	return ${STDLIB_HAVE_BASH_4}
} # __STDLIB_oneshot_get_bash_version


###############################################################################
#
# stdlib.sh - Standard overridable functions - Initialisation & clean-up
#
###############################################################################

# This function MUST be overridden, and contain all script code except for
# variable and function declarations.
#
# The code to include stdlib.sh may appear at top-level, within a separate
# function, or within main().
#
# N.B.: No API-version declaration here - this is fixed.
#
function main() {
	die "No override main() function defined"
} # main


# This function may be overridden
#
function __STDLIB_API_1_std::cleanup() {
	local rc="${1:-0}" ; shift
	local file

	# Remove any STDLIB-generated temporary file and exit.

	for file in "${__STDLIB_OWNED_FILES[@]:-}"; do
		[[ -n "${file:-}" && -e "${file}" ]] && \
			rm -f "${file}" >/dev/null 2>&1
	done
	unset file

	trap - EXIT INT QUIT TERM
	[[ -n "${__STDLIB_SIGEXIT:-}" ]] && trap ${__STDLIB_SIGEXIT} EXIT
	[[ -n "${__STDLIB_SIGINT:-}" ]] && trap ${__STDLIB_SIGINT} INT
	[[ -n "${__STDLIB_SIGQUIT:-}" ]] && trap ${__STDLIB_SIGQUIT} QUIT
	[[ -n "${__STDLIB_SIGTERM:-}" ]] && trap ${__STDLIB_SIGTERM} TERM

	exit ${rc}
} # __STDLIB_API_1_std::cleanup

# The 'std::cleanup' stub for the appropriate API should be in place by now...
#
export __STDLIB_SIGEXIT="$( trap -p EXIT | cut -d"'" -f 2 )"
export __STDLIB_SIGINT="$( trap -p INT | cut -d"'" -f 2 )"
export __STDLIB_SIGQUIT="$( trap -p QUIT | cut -d"'" -f 2 )"
export __STDLIB_SIGTERM="$( trap -p TERM | cut -d"'" -f 2 )"
trap std::cleanup EXIT INT QUIT TERM


# This function should be overridden, or the ${std_USAGE} variable define
#
function __STDLIB_API_1_usage-message() {
	warn "${FUNCNAME} invoked - please use 'std::usage-message' instead"

	std::usage-message "${@:-}"
} # __STDLIB_API_1_usage-message

# Heavyweight compatibility work-around:
export __STDLIB_usage_message_definition="$( typeset -f usage-message )"

# This function should be overridden, or the ${std_USAGE} variable defined
#
function __STDLIB_API_1_std::usage-message() {
	die "No override std::usage-message() function defined"

	# The following output will appear in-line after 'Usage: ${NAME} '...
	output 'Command summary, e.g. "-f|--file <filename> [options]"'
	echo <<END
Further instructions here, e.g.

	-f : Process the specified <filename>
	-h : Show this help information
END
	return 0
} # __STDLIB_API_1_std::usage-message

# This function may be overridden
#
function __STDLIB_API_1_std::usage() {
	local rc="${1:-0}" ; shift

	# Optional arguments should be denoted as '[parameter]', required
	# arguments as '<parameter>'.  Short and long options should be
	# separated by a vertical-bar, e.g.
	# 	showfiles [-l|--long] <directory>

	output -n "Usage: ${NAME} "
	if [[ -n "${std_USAGE:-}" ]]; then
		output "${std_USAGE}"
	else
		if [[ "$( typeset -f usage-message )" == "${__STDLIB_usage_message_definition}" ]]; then
			std::usage-message
		else
			usage-message
		fi
	fi

	exit ${rc}
} # __STDLIB_API_1_std::usage


###############################################################################
#
# stdlib.sh - Standard overridable functions - Logging functions
#
###############################################################################

function __STDLIB_API_1_std::wrap() {
	local prefix="${1:-}" ; shift
	local text="${@:-}"

	[[ -n "${text:-}" ]] || return 1

	# N.B.: It may be necessary to 'export COLUMNS' before this
	#       works - this variable isn't exported to scripts by
	#       default, and is lost on invocation.
	if [[ -n "${prefix:-}" ]]; then
		  output "${text}" \
		| fold -sw "$(( ${COLUMNS:-80} - ( ${#prefix} + 1 )))" \
		| sed "s/^/${prefix} /"
	else
		  output "${text}" \
		| fold -sw "$(( ${COLUMNS:-80} - 1))"
	fi

	return 0
} # __STDLIB_API_1_std::wrap

function __STDLIB_API_1_std::log() {
	local prefix="${1:-${std_LIB}}" ; shift
	local data="${@:-}" message

	# Assume that log messages should be written to a file (unless we're
	# debugging) ... otherwise, use note(), warn(), or error() to output
	# to screen.

	if [[ -z "${data:-}" ]]; then
		data="$( cat - )"
	fi
	[[ -n "${data:-}" ]] || return 1

	data="$( sed 's/\r//' <<<"${data}" )"

	if [[ "${std_LOGFILE:-}" == "syslog" ]]; then
		# We'll emulate 'logger -i' here, as we need to return and so
		# can't use 'exec logger' to maintain PID...
		message="[${$}]: ${prefix} ${data}"
		type -pf logger >/dev/null 2>&1 && logger \
			-t "${NAME}" -- "${message}" >/dev/null 2>&1
	fi

	local date="$( date -u +'%Y%m%d %R.%S' )"
	message="${NAME}(${$}) ${date} ${prefix} ${data}"

	# We don't care whether std_LOGFILE exists, but we do care whether it's
	# set...
	[[ -n "${std_LOGFILE:-}" && "${std_LOGFILE}" != "syslog" ]] \
		&& output "${message}" >>"${std_LOGFILE}" 2>&1

	if (( std_DEBUG )); then
		std::wrap "${prefix}" "${data}"
	fi

	return $(( ! std_DEBUG ))
} # __STDLIB_API_1_std::log

#
# N.B.: To prevent unnecessary indirection, call API-versioned functions below
#

# This function may be overridden
#
function __STDLIB_API_1_die() {
	[[ -n "${@:-}" ]] && std_DEBUG=1 __STDLIB_API_1_std::log >&2 "FATAL: " "${@}"
	__STDLIB_API_1_std::cleanup 1

	return 1
} # __STDLIB_API_1_die

# This function may be overridden
#
function __STDLIB_API_1_error() {
	std_DEBUG=1 __STDLIB_API_1_std::log >&2 "ERROR: " "${@:-Unspecified error}"

	return 1
} # __STDLIB_API_1_error

# This function may be overridden
#
function __STDLIB_API_1_warn() {
	std_DEBUG=1 __STDLIB_API_1_std::log >&2 "WARN:  " "${@:-Unspecified warning}"

	return 1
} # __STDLIB_API_1_warn


# This function may be overridden
#
function __STDLIB_API_1_note() {
	std_DEBUG=1 __STDLIB_API_1_std::log "NOTICE:" "${@:-Unspecified notice}"

	return 0
} # __STDLIB_API_1_note

function __STDLIB_API_1_notice() {
	__STDLIB_API_1_note "${@:-}"
} # __STDLIB_API_1_notice

# This function may be overridden
#
function __STDLIB_API_1_info() {
	std_DEBUG=1 __STDLIB_API_1_std::log "INFO:  " "${@:-Unspecified message}"

	return 0
} # __STDLIB_API_1_info

# This function may be overridden
#
function __STDLIB_API_1_debug() {
	(( std_DEBUG )) && __STDLIB_API_1_std::log >&2 "DEBUG: " "${@:-Unspecified message}"

	return $(( ! std_DEBUG ))
} # __STDLIB_API_1_debug


###############################################################################
#
# stdlib.sh - Standard functions - errno & friends
#
###############################################################################

function __STDLIB_oneshot_errno_init() {
	local count=1

	declare -a __STDLIB_errsym __STDLIB_errstr

	# TODO: This should really be sourced from an external config file...
	#
	__STDLIB_errsym[ ${count} ]="ENOTFOUND"	; __STDLIB_errstr[ ${count} ]="Parameter value not found"	; (( count ++ )) ;
	__STDLIB_errsym[ ${count} ]="EENV"	; __STDLIB_errstr[ ${count} ]="Invalid environment"		; (( count ++ )) ;
	__STDLIB_errsym[ ${count} ]="EARGS"	; __STDLIB_errstr[ ${count} ]="Invalid arguments"		; (( count ++ )) ;
	__STDLIB_errsym[ ${count} ]="ENOEXE"	; __STDLIB_errstr[ ${count} ]="Required executable not found"	; (( count ++ )) ;

	# These should appear, in order, last:
	__STDLIB_errsym[ ${count} ]="EERROR"	; __STDLIB_errstr[ ${count} ]="Undefined error"			; (( count ++ )) ;
	__STDLIB_errsym[ ${count} ]="ENOTSET"	; __STDLIB_errstr[ ${count} ]="Logic failure: errno unset"	; # Final item, no increment

	declare -i __STDLIB_errtotal="${count}"

	# Need ability to serialise arrays...
	#export __STDLIB_errsym __STDLIB_errstr __STDLIB_errtotal STDLIB_HAVE_ERRNO=1

	return 0
} # __STDLIB_oneshot_errno_init

function __STDLIB_API_1_symerror() {
	local err="${1:-${std_ERRNO:-}}"

	(( STDLIB_HAVE_ERRNO )) || {
		error "errno not initialised - please re-import ${std_LIB}" \
			"with 'STDLIB_WANT_ERRNO' set"
		return 1
	}

	if (( err > 0 && err < ${__STDLIB_errtotal:-0} )); then
		respond "${__STDLIB_errsym[ ${err} ]}"

		return 0
	else
		std_ERRNO=1

		return 1
	fi

	# Unreachable
	return 255
} # __STDLIB_API_1_symerror

function __STDLIB_API_1_errsymbol() {
	local symbol="${1:-}"
	local n

	(( STDLIB_HAVE_ERRNO )) || {
		error "errno not initialised - please re-import ${std_LIB}" \
			"with 'STDLIB_WANT_ERRNO' set"
		return 1
	}

	(( 0 == ${__STDLIB_errtotal:-0} )) && return 0

	for n in $( seq 0 (( ${__STDLIB_errtotal:-0} - 1 )) ); do
		if [[ "${symbol}" == "${__STDLIB_errsym[ ${n} ]}" ]]; then
			respond "${n}"
			return ${n}
		fi
	done

	return 0
} # __STDLIB_API_1_errsymbol

function __STDLIB_API_1_strerror() {
	local err="${1:-${std_ERRNO:-}}" ; shift
	local msg="Unknown error" rc=1

	(( STDLIB_HAVE_ERRNO )) || {
		error "errno not initialised - please re-import ${std_LIB}" \
			"with 'STDLIB_WANT_ERRNO' set"
		return 1
	}

	if [[ -z "${err:-}" ]]; then
		:
	#elif ! grep -q '^[0-9]\+$' <<<"${err}"; then
	elif ! echo "${err}" | grep -q '^[0-9]\+$'; then
		:
	else
		case "${err}" in
			0)
				msg=""
				rc=0
				;;
			*)
				msg="Unknown error ${err}"
				;;
		esac
	fi

	respond "${msg}"

	return ${rc}
} # __STDLIB_API_1_strerror


###############################################################################
#
# stdlib.sh - Standard functions - mktemp & friends
#
###############################################################################

function __STDLIB_API_1_std::garbagecollect() {
	local file rc

	# Add an additional file to the list of files to be removed when
	# std::cleanup is invoked.
	# This can be used to work-around the use of std::mktemp in a
	# sub-shell.

	for file in "${@:-}"; do
		[[ -e "${file}" ]] && {
			__STDLIB_OWNED_FILES=( ${__STDLIB_OWNED_FILES[@]:-} ${file} )
			rc=${rc:-0}
		} || rc=1
	done

	return ${rc:-1}
} # __STDLIB_API_1_std::garbagecollect

function __STDLIB_API_1_std::mktemp() {
	local message standard tmpdir opts file name

	# Create a temporary file, which will be removed by cleanup() on
	# program exit.

	# N.B.: mktemp is commonly invoked in a sub-shell - if this is the case
	#       then std::garbagecollect() must be explicitly called on the
	#       returned file-names, as the parent process will not have seen
	#       them.

	# If the first argument is a directory which already exists, then the
	# temporary file(s) will be created in this directory.

	# TODO:
	# Add option-parsing of mktemp options, specifically '-d' to create a
	# temporary directory.

	# CentOS/Red Hat seem to ship a 'mktemp' utility which differs from
	# that provided by GNU coreutils - presumably a legacy carry-over :(
	# (Un)helpfully, the non-GNU mktemp returns an error if you try to find
	# out what it is, which we can then take advantage of thusly:
	mktemp --version >/dev/null 2>&1
	case ${?} in
		0)
			message="GNU mktemp failed"
			standard=0
			;;
		1)
			message="legacy mktemp failed"
			standard=1
			;;
		*)
			die "Cannot detect mktemp version: ${?}"
			;;
	esac

	if [[ -d "${1:-}" ]]; then
		tmpdir="${1}"
		case ${standard} in
			0)
				# Note trailing space and quote...
				opts="--tmpdir=\"${tmpdir}\" \""
				;;
			1)
				# Note lack of trailing space before quote...
				opts="\"${tmpdir}\"/\""
				;;
		esac
	else
		tmpdir="${TMPDIR:-/tmp}"

		# Note trailing space and quote...
		opts="-t \""
	fi

	local -a __std_NEWFILES

	for file in "${@:-temp}"; do
		name="${NAME}.${file}.XXXXXXXX"

		# Otherwise undocumented, **potentially dangerous**, configuration setting...
		if [[ -n "${STDLIB_REUSE_TEMPFILES:-}" ]]; then
			file="$( ls -1 "${tmpdir}"/"${NAME}.${file}."* 2>/dev/null | tail -n 1 )"

			if [[ -e "${file}" ]]; then
				__STDLIB_OWNED_FILES=( ${__STDLIB_OWNED_FILES[@]:-} ${file} )

				cat /dev/null > "${file}" 2>/dev/null
				respond "${file}"

				continue
			fi
		fi

		__std_NEWFILES=(
			${__std_NEWFILES[@]:-}
			"$( eval "mktemp ${opts}${name}\"" || {
				error "${message}"
				return 1
			} )"
		)
	done

	if (( ${#__std_NEWFILES[@]} )); then
		__STDLIB_OWNED_FILES=( ${__STDLIB_OWNED_FILES[@]:-} ${__std_NEWFILES[@]} )

		for file in "${__std_NEWFILES[@]}"; do
			respond "${file}"
		done
	fi

	return 0
} # __STDLIB_API_1_std::mktemp

function __STDLIB_API_1_std::emktemp() {
	local var="${1}" ; shift
	local file files rc result

	# Invoke std::mktemp and automatically save the generated files for
	# later removal.
	# Rather than:
	#
	#   tempfile="$( mktemp -t "${0}"."${$}".XXXXXXXX )"
	#
	# ... or:
	#
	#   tempfile="$( std::mktemp "${$}" )"
	#
	# ... instead do:
	#
	#   std::emktemp tempfile "${$}"
	#
	# ... which will place the results into tempfile on success.

	files="$( __STDLIB_API_1_std::mktemp "${@:-}" )"
	rc=${?}

	if (( rc )); then
		return ${rc}
	else
		result=""
		while read -r file; do
			__STDLIB_API_1_std::garbagecollect "${file}" \
				&& result="$(
					echo -e "${result:+${result}\n}${file}"
				   )" \
				|| rc=1
		#done <<<"${files}"
		done < <( echo "${files}" )
	fi
	eval export "${var}"=\""${result}"\"

	return ${rc}
} # __STDLIB_API_1_std::emktemp


###############################################################################
#
# stdlib.sh - 'Push' from https://github.com/vaeth/push
#
###############################################################################

function __STDLIB_API_1_std::push() {
	local std_push_result="" std_push_var std_push_current std_push_segment std_push_arg std_push_add_quote=""
	local -i rc=0

set -o xtrace

	#
	# Usage: std::push [-c] VARIABLE [arguments]
	#
	# -c : Clear VARIABLE before adding [arguments]
	#
	# The arguments will be appended to VARIABLE in a quoted manner (with
	# quotes rarely used - the exact form depends on the version of the
	# script) so that an "eval" $VARIABLE obtains the collected arguments
	#

	# ... one of the most obfuscated shell functions I've ever come across

	# Clear accumulator, or save current VARIABLE contents...
	#
	case "${1:-}" in
		-c)
			shift
			;;
		*)
			# Get current value of VARIABLE...
			#
			eval std_push_result="\${${1:-}}"
			;;
	esac

	# Save variable name...
	#
	std_push_var="${1:-}"
	shift

	# Execute loop body once for each argument...
	#
	for std_push_arg in "${@:-}"; do

		# Append a space if already populated...
		#
		[[ -n "${std_push_result:-}" ]] && std_push_result="${std_push_result} "

		# If argument is unset (or starts with '=') or starts with '~'
		# then we apparently need to quote it later(?)
		#
		# TODO: What's magic about '~'?
		#       Is it a sole special-case for referencing
		#       home-directories?
		#
		unset std_push_add_quote
		#case "${std_push_arg:-=}" in
		#	[=~]*)
		#		std_push_add_quote="yes"
		#		;;
		#esac
		[[ "${std_push_arg:-}" =~ ^[=~] ]] && std_push_add_quote="yes"

		std_push_current="${std_push_arg:-}"

		# Deconstruct string based on single-quotes...
		#
		while std_push_segment="${std_push_current%%\'*}"; do

			# If argument was unset (or matched '^[=~]') and we're
			# on the first iteration, or the current segment
			# contains any problematic characters, then prefix the
			# current segment with a single quote...
			#
			# TODO: Strange choice of characters, and '!' was
			#       problematic.  What about ','?
			#       There must be a matching character-class?
			#
			#if ${PushF_-:} && case ${PushD_} in
			#	*[!-+=~/:.0-9_a-zA-Z]*)	false;;
			#
			if [[ -n "${std_push_add_quote:-}" || "${std_push_segment}" =~ [^-+=~/:.0-9_a-zA-Z] ]]; then
				std_push_result="${std_push_result}'${std_push_segment}'"
				unset std_push_add_quote
			else
				std_push_result="${std_push_result:-}${std_push_segment}"
			fi

			# Exit if there were no single quotes in the original
			# string...
			#
			[[ "${std_push_segment}" == "${std_push_current}" ]] && break

			# ... otherwise, add an escaped closing quote to the
			# result, and remove the section before the first
			# single-quote from the string being iterated over.
			#
			# TODO: Why wasn't the opening quote also escaped?
			#
			std_push_result="${std_push_result}\\'"
			std_push_current="${std_push_current#*\'}"
		done
	done

	# Assign result...
	eval "${std_push_var}=\"\${std_push_result}\""

	# ... and work out a return value...
	eval "[[ -n \"\${${std_push_var}:-}\" ]]"
	rc=${?}

set +o xtrace

echo "Debug: std_push_var='${std_push_var}', value=|$( eval echo \"\${${std_push_var}:-}\" )|, rc=${rc}"
	return ${rc}
} # __STDLIB_API_1_std::push


###############################################################################
#
# stdlib.sh - Standard functions - Platform-neutral readlink
#
###############################################################################

function __STDLIB_API_1_std::readlink() {
	local file="${1:-}" ; shift

	[[ -n "${file:-}" ]] || return 1

	# Find the target of a symlink, in circumstances where GNU readlink is
	# not available

	if [[ -L "${file}" ]]; then
		ls -l "${file}" | sed 's/^.* -> //'

		return 0
	else
		respond "${file}"

		return 1
	fi

	# Unreachable
	return 255
} # __STDLIB_API_1_std::readlink


###############################################################################
#
# stdlib.sh - Standard functions - Improved HEREDOC support
#
###############################################################################

function __STDLIB_API_1_std::define() {
	local var="${1:-}" ; shift

	# Usage:
	#
	# std::define MYVAR <<'EOF'
	# heredoc content to be read into $MYVAR without using 'cat'
	# You can 'quote ""things how you like...
	# ... $( and this won't be executed )!
	# EOF

	[[ -n "${var:-}" ]] || return 1

	IFS='\n' read -r -d '' ${var} || true
} # __STDLIB_API_1_std::define


###############################################################################
#
# stdlib.sh - Standard functions - Prepare a list of items for pretty-printing
#
###############################################################################

function __STDLIB_API_1_std::formatlist() {
	local item

	if [[ -n "${3:-}" ]]; then
		item="${1:-}"
		echo "${item:-}, $( ${FUNCNAME} "${@:-}" )"
	elif [[ -n "${2:-}" ]]; then
		item="$(
			for item in "${FUNCNAME[@]}"; do
				echo "${item}"
			done | grep -c "${FUNCNAME}"
		)"
		if (( item > 1 )); then
			echo "${1:-}, and ${2:-}"
		else
			echo "${1:-} and ${2:-}"
		fi
	else
		echo "${@:-}"
	fi

	return 0
} # __STDLIB_API_1_std::formatlist


###############################################################################
#
# stdlib.sh - Standard functions - Handle version-strings in a standard way
#
###############################################################################

function __STDLIB_API_1_std::vcmp() {
	local vone op vtwo list

	# Does system 'sort' have version-sort capability (again, CentOS/Red
	# Hat seem to lose out here...)
	sort --version-sort </dev/null || return 254

	if (( 3 == ${#@} )); then
		vone="${1:-}"
		op="${2:-}"
		vtwo="${3:-}"
	fi

	case "${op:-}" in
		'<'|lt|-lt)
			if [[ "${vone}" != "${vtwo}" && "$( echo -e "${vone}\n${vtwo}" | sort -V 2>/dev/null | head -n 1 )" == "${vone}" ]]; then
				# vone < vtwo
				return 0
			else
				# vone !< vtwo
				return 1
			fi
			;;
		'<='|le|-le)
			if [[ "${vone}" == "${vtwo}" || "$( echo -e "${vone}\n${vtwo}" | sort -V 2>/dev/null | head -n 1 )" == "${vone}" ]]; then
				# vone <= vtwo
				return 0
			else
				# vone > vtwo
				return 1
			fi
			;;
		'>'|gt|-gt)
			if [[ "${vone}" != "${vtwo}" && "$( echo -e "${vone}\n${vtwo}" | sort -V 2>/dev/null | tail -n +2 )" == "${vone}" ]]; then
				# vone > vtwo
				return 0
			else
				# vone !> vtwo
				return 1
			fi
			;;
		'>='|ge|-ge)
			if [[ "${vone}" == "${vtwo}" || "$( echo -e "${vone}\n${vtwo}" | sort -V 2>/dev/null | tail -n +2 )" == "${vone}" ]]; then
				# vone >= vtwo
				return 0
			else
				# vone < vtwo
				return 1
			fi
			;;
		*)
			list="$(
				for VERSION in "${@}"; do
					echo "${VERSION}"
				done | sort -V 2>/dev/null
			)"
			respond "${list}"
			[[ "$( echo "${list}" | xargs echo )" == "$( echo "${@}" | xargs echo )" ]] && return 0 || return 1
			;;
	esac

	# Unreachable
	return 255
} # __STDLIB_API_1_std::vcmp


###############################################################################
#
# stdlib.sh - Standard functions - Ensure that needed binaries are present
#
###############################################################################

function __STDLIB_API_1_std::requires() {
	local files
	local item
	local -i canexit=1
	local -i rc=0

	if [[ "${1}" =~ ^(--)?(no-?exit|no-?abort|keep|keep-?going)$ ]]; then
		canexit=0
		shift
	fi

	files="${@:-}"

	[[ -n "${files:-}" ]] || return 1

	for item in ${files}; do
		type -pf "${item}" >/dev/null 2>&1 || {
			error "Cannot locate required '${item}' binary"
			rc=1
		}
	done

	(( canexit & rc )) && exit 1

	return ${rc}
} # __STDLIB_API_1_std::requires


###############################################################################
#
# stdlib.sh - Helper functions - Capture output of commands
#
###############################################################################

function __STDLIB_API_1_std::capture() {
	local stream="${1:-}" ; shift
	local cmd="${1:-}" ; shift
	local arg="${@:-}" ; shift
	local redirect="" response=""
	local -i rc=0

	# Return the stdout or stderr output of a command in a consistent way.

	case "${stream:-}" in
		1|out|stdout)
			redirect="2>/dev/null"
			;;
		2|err|stderr)
			# N.B.: Ordering - ensure we still get stderr on &1
			redirect="2>&1 >/dev/null"
			;;
		all|both)
			redirect="2>&1"
			;;
		none)
			redirect=">/dev/null 2>&1"
			;;
		*)
			error "Invalid parameters: prototype '${FUNCNAME}" \
				"<stream> <command> [arguments]', received" \
				"'<${stream:-}> <${cmd:-}> [${arg:-}]'"
			return 255
			;;
	esac

	if ! type -t "${cmd:-}" >/dev/null; then
		error "Invalid parameters: <command> '${cmd:-}' not found"
		return 255
	fi

	response="$( eval "${cmd}" ${arg:-} ${redirect} )" ; rc=${?}
	output "${response:-}"

	return ${rc}
} # __STDLIB_API_1_std::capture

function __STDLIB_API_1_std::ensure() {
	local err="${1:-}" ; shift
	local cmd="${1:-}" ; shift
	local arg="${@:-}" ; shift
	local response=""
	local -i rc=0

	# If we're given an error message, silently succeed or fail with the
	# specified message; if we don't have an error message then output a
	# valid response or the command's failure text.

	if ! type -t "${cmd:-}" >/dev/null; then
		error "Invalid parameters: <command> '${cmd:-}' not found"
		return 255
	fi

	response="$( std::capture stderr "${cmd}" ${arg:-} )" ; rc=${?}
	if (( !( rc ) )); then
		# Succeeded
		[[ -z "${err:-}" ]] && output "${response:-}"

		return ${rc}
	else
		# Failed

		die "${err:-${response:-}}"
	fi

	# Unreachable
	return 255
} # __STDLIB_API_1_std::ensure

function __STDLIB_API_1_std::silence() {
	[[ -n "${1:-}" ]] || return 1

	std::capture all "${@:-}" >/dev/null

	return ${?}
} # __STDLIB_API_1_std::silence


###############################################################################
#
# stdlib.sh - Helper functions - Allow for parameterised arguments
#
###############################################################################

function __STDLIB_API_1_std::parseargs() {
	local current
	local arg
	local -i onevalue=0 unrecok=0 rc=1

	local unassigned="std_PARSEARGS_unassigned"

	if [[ "${1:-}" =~ ^(--)?strip$ ]]; then
		#respond "$(
		#for arg in $( echo "${@}" | sed -r 's/^.*\s+--\s+//' ); do
		#	echo "${arg:-}"
		#done | grep -v '^-'
		#)"
		echo "${@}" | sed -r 's/^.*\s+--\s+//'
		return 0
	fi

	arg="${unassigned}"

	(( STDLIB_HAVE_BASH_4 )) || {
		(( std_DEBUG )) && error "${FUNCNAME} requires bash-4 associative arrays"
		return 1
	}

	# It would sometimes be incredibly useful to be able to pass unordered
	# or optional parameters to a shell function, without the overhead of
	# having to run getopt and parse the output for every invokation.
	#
	# The aim here is to provide a function which can be called by 'eval'
	# in order to expand command-line arguments into variable declarations.
	#
	# For example:
	#
	#   function myfunc() {
	#     local item1 item2 item3
	#     eval $( std::parseargs "${@}" ) || {
	#       set -- $( std::parseargs --strip -- "${@}" )
	#       item1="${1:-}"
	#       item2="${2:-}"
	#       item3="${3:-}"
	#     }
	#     <...>
	#   }
	#
	#   myfunc a b c # -> Variables populated, as usual, by inner block
	#   myfunc -item3 c -item1 a -item2 b # -> Identical, but variables
	#                                          populated by parseargs()
	#
	# Parameters should be passed as a single hypen followed by the
	# variable name to set, then zero or more values for this variable.
	# Options with double-hyphens are processed by std::parseargs internally
	# in order to set default behaviour, and should all be passed prior to
	# a double-hyphen.
	# The return-code is zero if we have managed to populate at least one
	# variable with a value, for one otherwise.
	#
	# Any values without an obvious associated variable name are saved as
	# "std_PARSEARGS_unassigned"
	#
	# Internal options:
	#   --single     - Only store the value following a variable to that
	#                  variable, rather than storing everything until the
	#                  next variable name;
	#   --permissive - Don't return an error if no values are recognised
	#   --var <name> - Specify the variable name for unrecognised values

	local -A result

	if grep -qw -- '--' <<<"${@}"; then
		local options="$( sed -r 's/^(.*)\s+--\s.*$/\1/' <<<" ${@} " )"
		local args="$( sed -r 's/^.*\s--\s+(.*)$/\1/' <<<" ${@} " )"

		set -- ${options}
		while [[ -n "${1:-}" ]]; do
			current="${1}" ; shift
			case "${current}" in
				--onevalue|--single)
					onevalue=1
					;;
				--unrecok|--permissive)
					unrecok=1
					;;
				--unrec|--unknown|--variable|--var)
					unassigned="${1:-}" ; shift
					;;
				*)
					(( std_DEBUG )) && error "${FUNCNAME}: Unknown option '${current}'"
					return 1
					;;
			esac
		done
		if ! [[ -n "${unassigned:-}" && "${unassigned}" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
			(( std_DEBUG )) && error "${FUNCNAME}: Specified name '${unassigned:-}' is not a valid variable-name"
			return 1
		fi

		set -- ${args}

		unset args options
	fi

	while [[ -n "${1:-}" ]]; do
		current="${1}" ; shift

		(( 0 == ${#current} )) && continue

		if [[ "${current:0:1}" == "-" ]]; then
			arg="${current:1}"

			# Not necessarily IEEE 1003.1-2001, but according to
			# bash source...
			if ! [[ "${arg}" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
				(( std_DEBUG )) && error "${FUNCNAME}: Provided name '${arg:-}' is not a valid variable-name"
				return 1
			fi
		else
			[[ -n "${arg:-}" ]] || \
				warn "${FUNCNAME}: Dropping argument '${current}'"

			local existing="${result[${arg}]:-}"
			if [[ -n "${existing:-}" && -n "${existing// /}" ]]; then
				result[${arg}]="${existing} ${current}"
			else
				result[${arg}]="${current}"
			fi
			if (( unrecok )) || [[ "${arg}" != "${unassigned}" ]]; then
				rc=0
			fi
			(( onevalue )) && arg="${unassigned}"
		fi
	done

	if (( ! rc )); then
		for arg in "${!result[@]}"; do
			current="${result[${arg}]}"
			if [[ "${current}" =~ \  ]]; then
				respond "${arg// }='${current:-}'"
			else
				respond "${arg// }=${current:-}"
			fi
		done
	fi

	return ${rc}
} # __STDLIB_API_1_std::parseargs


###############################################################################
#
# stdlib.sh - Code samples - Sample functions
#
###############################################################################

# Sample iterator function
#function iterate_vars() {
#	local var1 var2 var3 var4 var5 counter=5 count
#
#	(( count = 1 ))
#	while (( count <= counter )); do
#		var="$( eval echo "\$var$count" )"
#		# 'var' is now set to the appropriate value
#		# Use 'var'...
#		(( count++ ))
#	done
#} # iterate_vars
#
#function iterate_array() {
#	declare -a array
#	local counter="${#array[@]}" count
#
#	(( count = 0 ))
#	while (( count <= counter )); do
#		var="${array[$count]}"
#		# Use 'var'...
#		(( count++ ))
#	done
#} # iterate_array

# Sample function which can take arguments via a pipe or as an argument
#function write() {
#	if (( 0 == $# )); then
#		cat -
#	else
#		[[ -n "${@:-}" ]] && echo -e "${@}"
#	fi
#} # write

# Sample function to write a lock-file
#function lock() {
#	local lockfile="${1:-/var/lock/${NAME}.lock}"
#
#	mkdir -p "$( dirname "$lockfile" )" 2>/dev/null || exit 1
#
#	if ( set -o noclobber ; echo "$$" >"$lockfile" ) 2>/dev/null; then
#		trap cleanup EXIT INT QUIT TERM
#	else
#		exit 1
#	fi
#} # lock


###############################################################################
#
# stdlib.sh - Code samples - Useful functions
#
###############################################################################

# ${#x} returns the length of the contents of ${x}:
#
#if (( 5 == "${#var}" )); then

# Iterate over data with 'read' without losing the ability to persist variable
# values:
#
#while read -r LINE; do
#	...
#done < $file
#
#while read -r LINE; do
#	...
#done < <( command )

# c.f. A non-working approach using pipes:
#
#myvar=1
#cat $file | while read -r LINE; do
#	myvar=2
#done
#echo $myvar
#
# ... which will always output '1' as the pipe causes the loop to execute
# within a sub-shell, causing local changes to be lost on completion.

# For all defined functions, select those containing a given 'canary'
# definition:
#
#local prefix="STDLIB" canary="local stdlib_canary=1;" stdlib_alias
#for function in ${__STDLIB_functionlist[@]}; do
#	set | awk "
#		 BEGIN			{
#			output = 0 ;
#		 } ;
#		/^${function} \(\) $/	{
#			output = 1 ;
#			print '${prefix}' \$1 ;
#		 } ;
#		/^}$/			{
#			2 == output && output = 0 ;
#		 } ;
#		/\s*${canary}$/ && ( 2 == output ) {
#			print \$0 ;
#		 } ;
#		/^{ $/			{
#			1 == output && output = 2 ;
#		 } ;
#	"
#done | grep -B 1 "${canary}" | grep "^${prefix}" | while read stdlib_alias; do
#	unalias $stdlib_alias 2>/dev/null
#done


###############################################################################
#
# stdlib.sh - Final setup and API mapping
#
###############################################################################

__STDLIB_oneshot_get_bash_version
unset __STDLIB_oneshot_get_bash_version

if [[ -n "${STDLIB_WANT_ERRNO:-}" ]] && (( !( STDLIB_HAVE_ERRNO ) )); then
	# Initialise errno functions...
	__STDLIB_oneshot_errno_init
	unset __STDLIB_oneshot_errno_init
fi

declare -i __STDLIB_API="${STDLIB_API:-1}"
case "${__STDLIB_API}" in
	1)
		:
		;;
	*)
		# Don't use die(), which is not yet defined...
		#
		output >&2 "API ${__STDLIB_API} not supported"
		exit 1
		;;
esac
export __STDLIB_API

# Following the same logic as suggested at the top of stdlib.sh, locate this
# script to allow for introspection.
# N.B.: Search order is (broadly) reversed, with a specified path tried first.
#
# stdlib.sh should be in /usr/local/lib/stdlib.sh, which can be found as
# follows by scripts located in /usr/local/{,s}bin/...
#
std_LIB="${std_LIB:-stdlib.sh}"
for std_LIBPATH in \
	 ${std_LIBPATH:-} \
	"/usr/local/lib" \
	"$( readlink -e "$( dirname -- "${BASH_SOURCE:-${0:-.}}" )/../lib" )" \
	"$( dirname "$( type -pf "${std_LIB}" 2>/dev/null )" )" \
	"." \
	 ${FPATH:+${FPATH//:/ }} \
	 ${PATH:+${PATH//:/ }}
do
	[[ -n "${std_LIBPATH:-}" ]] || continue

	if [[ -r "${std_LIBPATH}/${std_LIB}" ]]; then
		break
	fi
done
if [[ -r "${std_LIBPATH}/${std_LIB}" ]]; then
	if (( ${std_DEBUG:-0} )) \
		&& [[ "${std_LIBPATH=}" != "/usr/local/lib" ]]; then
		output >&2 "WARN:   ${std_LIB} Internal: Including ${std_LIB}"
			"from non-standard path '${std_LIBPATH}'"
	fi
else
	output >&2 "FATAL:  Cannot locate ${std_LIB} library functions"
	exit 1
fi
export std_LIBPATH std_LIB

# Red Hat/CentOS 5.x ship with a version of grep which can't parse '\s', and
# so '[[:space:]]' has to be used instead.  We can work around this as follows,
# but it does negatively impact processing speed:
declare s='\s'
echo " " | eval "grep -Eq '${s}'" || s='[[:space:]]'

# Create interface for functions of the appropriate API...
#
# N.B.: Avoid pipes to maintain scope of new definitions.
#
declare -a __STDLIB_functionlist
while read fapi; do

	# Export all API versions, so that explicit implmentations are still
	# available...
	#
	#if grep -q "^__STDLIB_API_" <<<"${fapi}"; then
	if echo "${fapi}" | grep -q "^__STDLIB_API_"; then

		# Ensure that function is still available...
		#
		if [[ "function" == "$( type -t "${fapi}" 2>/dev/null )" ]]; then

			# Make functions available to child shells...
			#
			export -f "${fapi}"

			if echo "${fapi}" | grep -q "^__STDLIB_API_${__STDLIB_API}_"; then
				if fname="$( sed 's/^__STDLIB_API_[0-9]\+_//' <<<"${fapi}" )"; then
					__STDLIB_functionlist=( ${__STDLIB_functionlist[@]:-} "${fname}" )
					eval "function ${fname}() { ${fapi} \"\${@:-}\"; }"

					# Make functions available to child shells...
					#
					export -f "${fname}"

					# Clear the variable, not the function definition...
					#
					unset fname
				fi
			fi
		fi
	fi

	#
	# Here's a strange thing... 'grep' in CentOS 5.8 (and likely others)
	# doesn't like '\s', so this needs to be swapped for the longer and
	# less readable '[[:space:]]' in the code below...
	#
	#  grep '^[[:space:]]*function[[:space:]]\+[a-zA-Z_]\+[a-zA-Z0-9_-]*[[:space:]]*()[[:space:]]*{\?[[:space:]]*$'
	#
	# ... or, experiments show, \W ([^[:alnum:]]) seems to be an
	# acceptable alternative (as would '[ ${std_TAB}]' be)!
	#
	# N.B.: Moved comment above code below due to syntax-highlighter
	# breakage.
	#
	#| grep '^\W*function\W\+[a-zA-Z_]\+[a-zA-Z0-9_:\-]*\W*()\W*{\?\W*$' \
	#
	# Update: Reverted to 'grep -E' from the above
	#

done < <(
	  grep "function" "${std_LIBPATH:-.}/${std_LIB}" \
	| sed 's/#.*$//' \
	| eval "grep -E '^${s}*function${s}+[a-zA-Z_]+[a-zA-Z0-9_:\-]*${s}*\(\)${s}*\{?${s}*$'" \
	| sed -r 's/^\s*function\s+([a-zA-Z_]+[a-zA-Z0-9_:\-]*)\s*\(\)\s*\{?\s*$/\1/'
)
unset fapi s

# Also export non-API-versioned functions...
#
export -f output respond

# Need ability to serialise arrays...
#export __STDLIB_functionlist

export STDLIB_HAVE_STDLIB=1

fi # [[ -z "${STDLIB_HAVE_STDLIB:-}" ]] # Line 10


if [[ -r "${std_LIBPATH}"/memcached.sh ]]; then
	if [[ -n "${STDLIB_WANT_MEMCACHED:-}" ]] \
		&& (( !( STDLIB_HAVE_MEMCACHED ) ))
	then
		source "${std_LIBPATH}"/memcached.sh \
			&& export STDLIB_HAVE_MEMCACHED=1
	fi
fi


###############################################################################
#
# stdlib.sh - EOF
#
###############################################################################

# set vi: syntax=sh colorcolumn=80 foldmethod=marker nowrap:
