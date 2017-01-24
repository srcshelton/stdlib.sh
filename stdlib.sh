#! /usr/bin/env bash
#
# Copyright 2013-2017 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2
#
# stdlib.sh standardised shared shell functions...

set +o xtrace

###############################################################################
#
# stdlib.sh - How to load ...
#
###############################################################################

# Pull this file into external scripts as follows:
#
: >/dev/null <<\EOC
# --- CUT HERE ---

# stdlib.sh should be in /usr/local/lib/stdlib.sh, which can be found as
# follows by scripts located in /usr/local/{,s}bin/...
declare std_LIB='stdlib.sh'
type -pf 'dirname' >/dev/null 2>&1 || function dirname() { : ; }
# shellcheck disable=SC2153
for std_LIBPATH in							\
	"$( dirname -- "${BASH_SOURCE:-${0:-.}}" )"			\
	'.'								\
	"$( dirname -- "$( type -pf "${std_LIB}" 2>/dev/null )" )"	\
	"$( dirname -- "${BASH_SOURCE:-${0:-.}}" )/../lib"		\
	'/usr/local/lib'						\
	 ${FPATH:+${FPATH//:/ }}					\
	 ${PATH:+${PATH//:/ }}
do
	if [[ -r "${std_LIBPATH}/${std_LIB}" ]]; then
		break
	fi
done
unset -f dirname

# Attempt to use colourised output if the environment indicates that this is
# an appropriate choice...
[[ -n "${LS_COLORS:-}" ]] &&
	export STDLIB_WANT_COLOUR="${STDLIB_WANT_COLOUR:-1}"

# We want the non if-then-else functionality here - the third element should be
# executed if either of the first two fail...
#
# N.B. The shellcheck 'source' option is only valid with shellcheck 0.4.0 and
#      later...
#
# shellcheck disable=SC1091,SC2015
# shellcheck source=/usr/local/lib/stdlib.sh
[[ -r "${std_LIBPATH}/${std_LIB}" ]] && source "${std_LIBPATH}/${std_LIB}" || {
	# shellcheck disable=SC2154
	echo >&2 "FATAL:  Unable to source ${std_LIB} functions:" \
		 "${?}${std_ERRNO:+ (ERRNO ${std_ERRNO})}"
	exit 1
}

# --- CUT HERE ---
EOC

# If you wish to ensure that a given minimum version of stdlib.sh is present
# from within a script, then this can be acheieved as follows (substituting
# versions '2.0.0' and '2.0.4' as appropriate):
#
: >/dev/null <<\EOC
# --- CUT HERE ---

# std_RELEASE was only added in release 1.3, and std::vcmp appeared immediately
# after in release 1.4...
if [[ "${std_RELEASE:-1.3}" == "1.3" ]] || std::vcmp "${std_RELEASE}" -lt "2.0.0"; then
	die "stdlib is too old - please update '${std_LIBPATH}/${std_LIB}' to at least v2.0.0" # for API 2
elif std::vcmp "${std_RELEASE}" -lt "2.0.4"; then
	warn "stdlib is outdated - please update '${std_LIBPATH}/${std_LIB}' to at least v2.0.4" # for std_LASTOUTPUT
fi

# --- CUT HERE ---
EOC


# Externally set control-variables:
#
# STDLIB_WANT_API	- Specify the stdlib API to adhere to, currently only
# 			  API versions '1' and '2' are supported values;
#
# Set (to '1') to activate:
#
# STDLIB_WANT_MEMCACHED	- Load native memcached functions, requires presence of
# 			- external '/usr/local/lib/memcached.sh' script;
# STDLIB_WANT_COLOUR	- Enable coloured output;
# STDLIB_WANT_WORDWRAP	- Set to zero to explicitly disable word-wrapping,
#			  leave unset to word-wrap if the terminal width can be
#			  determined, or set to one to explicitly force word-
#			  wrapping - to 80 columns if no width can be
#			  determined;
#			  (Invoking 'export COLUMNS' prior to executing a
#			   a script which in turn calls stdlib.sh may help)
#
# STDLIB_COLOUR_MAP	- Specify the path to an optional custom colour map
# 			  file, defaulting to '/etc/stdlib/colour.map';
#
# Exported control-variables:
#
# STDLIB_HAVE_STDLIB	- Set once stdlib functions have been loaded;
# STDLIB_HAVE_BASH_4	- Set if interpreter is bash-4 or above;
# STDLIB_HAVE_ERRNO	- Set if errno functions have been initialised;
# STDLIB_HAVE_MEMCACHED	- Set if bash memcached interace is available.
# STDLIB_HAVE_COLOUR	- Enable coloured output;
#
# Externally referenced variables:
#
# std_USAGE		- Specify simple usage strings.  For more complex
# 			  requirements, instead override usage-message;
# std_ERRNO		- Return an additional error-indication from a
# 			  function.
# std_LASTOUTPUT	- A copy of the last output written, to aid in output
#			  formatting (in order to determine whether the last
#			  thing written was a blank line, for example...)
#


###############################################################################
#
# stdlib.sh - Initialisation
#
###############################################################################

# Only load stdlib once, and provide support for loading stdlib from bashrc to
# reduce startup times...
#
if [[ "$( type -t 'std::sentinel' 2>&1 )" == 'function' ]]; then # {{{
	# We've already initialised, and all funcions are (assumed to be)
	# present.

	# ... however, if we're the child of a parent which included stdlib,
	# then we appear to inherit all functions and non-array variables, but
	# lose (at least) associative arrays.  In this case, we need to re-load
	# these data-structures.  This does mean that we can no longer unset
	# one-shot functions for efficiency's sake :(

	# N.B. __STDLIB_SHLVL is initialised below on first load, and so should
	#      still be present (and set) if std::sentinel exists as a function
	if ! (( __STDLIB_SHLVL == SHLVL )); then
		__STDLIB_oneshot_errno_init
		__STDLIB_oneshot_colours_init

		# ... also reset NAME, which likely now refers to the parent
		# also:

		NAME="$( basename -- "${0:-${std_LIB:-stdlib.sh}}" )"
		[[ "${NAME:-}" == "$( basename -- "${SHELL:-bash}" )" ]] &&
			NAME="${std_LIB:-stdlib.sh}"
	fi
else # See line 3339

declare -i __STDLIB_SHLVL=${SHLVL:-1}

if [[ -n "${STDLIB_HAVE_STDLIB:-}" ]]; then

	# We only get here if std::sentinel (see above) is unset but we still
	# have STDLIB_HAVE_STDLIB set - this has been observed post-Shellshock
	# due to the security changes applied to bash...

	if [[ -z "${NAME:-}" ]]; then

		# shellcheck disable=SC2031

		if [[ -z "${std_LIB:-}" ]]; then
			std_LIB="${std_LIB:-stdlib.sh}"
		fi
		NAME="$( basename -- "${0:-${std_LIB}}" )"
		[[ "${NAME:-}" == "$( basename -- "${SHELL:-bash}" )" ]] &&
			NAME="${std_LIB}"
	fi
	echo >&2
	echo >&2 "WARN:   ${NAME} variables have been imported, but function definitions are"
	echo >&2 'WARN:   missing - parent shell may be running in restricted, setuid, or'
	echo >&2 'WARN:   privileged mode.'
	echo >&2
	echo >&2 "NOTICE: Re-executing ${NAME} to re-generate all functions."
	echo >&2
fi # }}}


###############################################################################
#
# stdlib.sh - Release notes
#
###############################################################################

# What API version are we exporting?
#
# The version format used for this project is:
# <Highest API version>.<Major version>[.<Minor version>]
#
#export  std_RELEASE='1.3'   # Initial import;
#export  std_RELEASE='1.4'   # Add std::parseargs;
#export  std_RELEASE='1.4.1' # Add std::define;
#export  std_RELEASE='1.4.2' # Add std::getfilesection, std::configure;
#export  std_RELEASE='1.4.4' # Re-load stdlib if functions aren't present due
                             # to bash privileged_mode changes;
#export  std_RELEASE='1.4.5' # Update exit-code and and add HTTP mapping
                             # functions;
#export  std_RELEASE='1.4.6' # Fix issues identified by shellcheck.net, and
                             # improve MacOS compatibility;
#export  std_RELEASE='1.4.7' # Fix warnings identified by shellcheck.net, add
                             # std::wordsplit;
#export  std_RELEASE='1.5.0' # Add std::inherit, finally make errno functions
                             # work!  Set std_ERRNO where appropriate;
#export  std_RELEASE='1.5.1' # Added support for coloured output via
                             # std::colour and add std::findfile, fix
                             # std::parseargs to handle multi-element input and
                             # to return arrays (which is luckily non API-
                             # breaking);
#export  std_RELEASE='2.0.0' # std::inherit becomes the first function to be
                             # available in multiple API versions.  std::wrap
                             # now appends a lower-case (optional) prefix to
                             # wrapped follow-on lines.  Many fixes for correct
                             # operation when inheriting stdlib from parent
                             # shell.  std::requires now works properly ;)
#export  std_RELEASE='2.0.1' # std::*mktemp now support '-directory' to cause
                             # creation a temporary directory.  std::parseargs
                             # can now handle defined parameters with no value;
#export  std_RELEASE='2.0.2' # Make wrapping via std::wrap optional;
#export  std_RELEASE='2.0.3' # Ensure that required shell tools are available,
                             # and that traps are correctly initialised.
#export  std_RELEASE='2.0.4' # Add std_LASTOUTPUT support.
#export  std_RELEASE='2.0.5' # Enhance representation of std_TAB and std_NL,
                             # add std_CR and std_LF (as GitHub is unhappy with
                             # embedded carriage-return characters).
export   std_RELEASE='2.0.6' # Disable tracing for internal functions, unless
                             # DEBUG=2, to aid external debugging.
readonly std_RELEASE


###############################################################################
#
# stdlib.sh - Debugging options
#
###############################################################################

declare std_DEBUG
# Standard usage is:
#
std_DEBUG="${DEBUG:-0}"

declare std_TRACE
# Standard usage is:
#
# shellcheck disable=SC2034
std_TRACE="${TRACE:-0}"
#
# ... and then include:
#
: >/dev/null <<\EOC
# --- CUT HERE ---
(( std_TRACE )) && set -o xtrace
# --- CUT HERE ---
EOC
#
# ... near the top of the calling script.
#
# A good way to tell whether 'xtrace' is enabled is `[[ "${-/x}" != "${-}" ]]`


###############################################################################
#
# stdlib.sh - Logging
#
###############################################################################

# If this is not overridden, then logging will be disabled:
#
declare std_LOGFILE='/dev/null'
#
# Note that std_LOGFILE may also be given the special value of "syslog" to use
# 'logger'(1) to send messages to any local syslogd.


###############################################################################
#
# stdlib.sh - Notes
#
###############################################################################

# All scripts should end with the following lines (or similar):
#
: >/dev/null <<\EOC
# --- CUT HERE ---
function main() {
	...
} # main

main "${@:-}"

exit ${?}

# vi: set syntax=sh colorcolumn=80 foldmethod=marker:
# --- CUT HERE ---
EOC


# A note on standard/reserved return/exit codes with special meanings:
#
#        Code	Meaning
# -----------	-------
#           1	General error
#           2	Misuse of shell builtin (missing keyword or command, or
#		permission problem)
#         126	Command invoked cannot execute (command is not an executable?)
#         127	"command not found" - specified command does not exist in $PATH
#         128	Invalid argument to exit
#  129 to 192	Exited due to signal 'x' where 'x' is ( ${?} - 128 )
#		e.g. 130 == 2 + 128 == SIGINT (see `kill -l`) == Ctrl + C
#         255	Exit status out of range (e.g. `exit -1` is invalid)
#
# If possible, code should either try to employ these conventions or, at least,
# avoid the above reserved values - use of `exit 127`, for example, could be
# very confusing or misleading to the user or to other tools.
#
# Alternatively, attempt to exclusively use return-codes 0 and 1 to flag
# success and failure respectively, and then use the ERRNO functions below to
# provide richer context.  stdlib.sh uses this convention, with 'return 255'
# appearing for debug purposes to signal the execution of code thought to be
# unreachable.


###############################################################################
#
# stdlib.sh - Setup and standard functions
#
########################################################################### {{{

# Throw an error if parameter-expansion occurs with an unset variable.
#
# Gentleman, start your debuggers ;)
#
set -u

# Try to impose sane handling of the '!' character...
#
set +o histexpand

# Prevent non-matching shell globs from being literally interpreted...
#
#shopt -qs nullglob
# ... or abort when a glob fails to match anything:
shopt -qs failglob


# Use 'output' rather than 'echo' to clearly differentiate user-visible
# output from pipeline-intermediate commands.
#
function output() {
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local flags='-e'

	if ! [[ -n "${*:-}" ]]; then
		echo
		std_LASTOUTPUT=""
	else
		[[ " ${1:-} " == ' -n ' ]] && { flags+='n' ; shift ; }
		echo ${flags} "${*}"
		std_LASTOUTPUT="${*}"
	fi

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return 0
} # output

# Use 'respond' rather than 'echo' to clearly differentiate function results
# from pipeline-intermediate commands.
#
function respond() {
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	[[ -n "${*:-}" ]] && echo "${*}"

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return 0
} # respond

# Use of aliases requires more investigation to ensure reliability.
#
## N.B.: Set this in order to have aliases interpreted by scripts...
##
##shopt -qs expand_aliases
##alias output='echo -e'
##alias respond='echo'

# }}}


###############################################################################
#
# stdlib.sh - Standard functions and variables
#
########################################################################### {{{

unalias cp >/dev/null 2>&1
unalias ls >/dev/null 2>&1
unalias mv >/dev/null 2>&1
unalias rm >/dev/null 2>&1

export std_PREFIX="${std_PREFIX:-/usr/local}"
export std_BINPATH="${std_PREFIX}/bin"
# N.B.: Earlier auto-discovered value for std_LIBPATH is replaced here:
export std_LIBPATH="${std_PREFIX}/lib"

# ${0} may equal '-bash' if invoked directly, in which case some tools may fail
# if they try to interpret '-b ash'.
#
# At this point, before we've been able to run std::requires, try to work out
# our name without relying on external binaries such as 'basename' or
# 'dirname'...
#
declare NAME="${0:-${std_LIB:-stdlib.sh}}"
NAME="${NAME##*/}"
if [[ -n "${SHELL:-}" ]]; then
	[[ "${NAME:-}" == "${SHELL##*/}" || "${NAME:-}" == "-${SHELL##*/}" ]] &&
		NAME="${std_LIB:-stdlib.sh}"
else # [[ -z "${SHELL:-}" ]]; then
	[[ "${NAME:-}" == 'bash' || "${NAME:-}" == '-bash' ]] &&
		NAME="${std_LIB:-stdlib.sh}"
fi
export NAME

# Ensure a sane sorting order...
export LC_ALL='C'

# These values should make certain code much clearer...
declare std_TAB std_CR std_LF std_NL
std_TAB="$( printf "\t" )"
std_CR="$( printf "\r" )"
std_LF="$( printf "\n" )"
std_NL="${std_LF}"
export std_TAB std_CR std_LF std_NL

# We don't want to rely on $SHELL so, as an alternative, this should work - but
# is also a little bit scary...
#
declare -i STDLIB_HAVE_BASH_4=0

export STDLIB_HAVE_ERRNO=0
export STDLIB_HAVE_STDLIB=0
export STDLIB_HAVE_MEMCACHED=0

export std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

export std_LASTOUTPUT=""

declare -a __STDLIB_OWNED_FILES

# }}}


###############################################################################
#
# stdlib.sh - Shell detection
#
###############################################################################

# N.B.: In general, we don't want to reference ${0} as it may be unreliable if
#       we're sourced from a script itself sourced from another script... but
#       in this case the ultimate parent does impose the interpreter.
#
function __STDLIB_oneshot_get_bash_version() { # {{{
	set +o xtrace

	local parent="${0:-}"
	local int shell version

	if [[ -n "${BASH_VERSION:-}" ]]; then
		if (( ${BASH_VERSION%%.*} >= 4 )); then
			STDLIB_HAVE_BASH_4=1
		else
			STDLIB_HAVE_BASH_4=0
		fi
		export STDLIB_HAVE_BASH_4

		std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
		return ${STDLIB_HAVE_BASH_4}
	fi

	# Please note - this function may have unintended consequences if
	# invoked from a script which has an interpreter which causes a
	# permanent state-change if executed with '--version' as a parameter.

	if [[ -z "${parent:-}" || "$( basename -- "${parent#-}" )" == 'bash' ]]; then
		# If stdlib.sh is sourced directly, $0 will be 'bash' (or
		# another shell name, which should be listed in /etc/shells)
		#
		if [[ -n "${SHELL:-}" ]]; then
			shell="$( basename "${SHELL}" )"
		else
			shell='bash' # We'll assume...
		fi

	elif [[ -r "${parent}" ]]; then
		# Our interpreter should be some valid shell...
		int="$( head -n 1 "${parent}" )"
		local sed='sed -r'
		${sed} '' >/dev/null 2>&1 <<<'' || sed='sed -E' # ` # <- Ubuntu syntax highlight fail
		int="$( ${sed} 's|^#\! ?||' <<<"${int}" )"
		unset sed
		if [[ \
			"${int:0:4}" == 'env ' ||
			"${int:0:9}" == '/bin/env ' ||
			"${int:0:13}" == '/usr/bin/env ' \
		]]; then
			shell="$( cut -d' ' -f 2 <<<"${int}" )"
		else
			shell="$( cut -d' ' -f 1 <<<"${int}" )"
		fi

	else
		warn 'Unknown interpretor'
	fi

	if [[ -n "${shell:-}" ]]; then
		# XXX: Use std::readlink for cross-platform support...
		shell="$( readlink -e "$( type -pf "${shell:-bash}" 2>/dev/null )" )"
		if [[ -n "${shell:-}" && -x "${shell}" ]]; then
			version="$( "${shell}" --version 2>&1 | head -n 1 )" ||
				die 'Cannot determine version for' \
				    "interpreter '${shell}'"
			if grep -q '^GNU bash, version ' >/dev/null 2>&1 \
					<<<"${version}"; then
				if ! grep -q " version [0-3]" >/dev/null 2>&1 \
						<<<"${version}"; then
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

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
	return ${STDLIB_HAVE_BASH_4}
} # __STDLIB_oneshot_get_bash_version # }}}


###############################################################################
#
# stdlib.sh - Validate syntax
#
###############################################################################

function __STDLIB_oneshot_syntax_check() { # {{{
	set +o xtrace

	local script

	if ! (( STDLIB_HAVE_BASH_4 )) || ! [[ -n "${SHELL:-}" && "${SHELL}" =~ bash$ ]]; then
		std_ERRNO=$( errsymbol ENOEXE )
		return 0
	else
		local -Ai seen

		while read -r script; do
			(( ${seen[${script}]:-0} )) && continue
			seen[${script}]=1

			if ! [[ -s "${script}" ]]; then
				(( std_DEBUG )) && echo >&2 "DEBUG:  Skipping syntax validation of unreadable script '${script}' ..."
			else
				(( std_DEBUG )) && echo >&2 "DEBUG:  Syntax validating script '${script}' ..."
				"${SHELL}" -n "${script}" || {
					echo >&2 "FATAL:  Syntax error detected in '${script}'"

					std_ERRNO=5 # instead use 'std_ERRNO=$( errsymbol ESYNTAX )'
					return 1
				}
			fi
		done < <( printf '%s\n' "${BASH_SOURCE[@]:-}" /usr/local/lib/stdlib.sh | sort | uniq )
	fi

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
	return 0
} # __STDLIB_oneshot_syntax_check # }}}


###############################################################################
#
# stdlib.sh - Initialise coloured output
#
###############################################################################

## shellcheck gets confused by the constants used below...
# shellcheck disable=SC2154
function __STDLIB_oneshot_colours_init() { # {{{
	set +o xtrace

	local file key value val
	local -l section
	local -i fg bg mode

	if ! (( ${STDLIB_WANT_COLOUR:-0} )); then
		std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
		return 0
	fi
	# For efficiency purposes, we'll store colour mappings in an
	# associatve array and so only support colouration with bash-4
	#
	if ! (( STDLIB_HAVE_BASH_4 )); then
		STDLIB_WANT_COLOUR=0
		std_ERRNO=$( errsymbol EENV )
		return 1
	fi
	if ! (( $( tput cols 2>/dev/null || echo '0' ) )); then
		# We're not connected to a terminal
		STDLIB_WANT_COLOUR=0
		std_ERRNO=$( errsymbol EACCESS )
		return 0
	fi

	# XXX: Somehow, this breaks standard shell '-e' and '-x' functions!?
	#tput init 2>/dev/null

	# We can't use -Agix here, because we can't then differentiate between
	# unset and zero (black)...
	# XXX: It might be worth storing SGR values rather than colour indices
	#      here to avoid this ambiguity?
	declare -Agx __STDLIB_COLOURMAP

	# TODO: Support 16 colours using values 90 (fg-black) to 107 (bg-white)
	#       and 88/256 colour mode using '38;5;<bg>' and '48;5;<fg>' escape
	#       sequences...
	#
	# black is \e[30m.
	local -i black=0 red=1 green=2 yellow=3 blue=4 magenta=5 cyan=6 white=7
	local -i default=9
	local -i bold=1 underline=4 inverse=7

	# TODO: Read in categories from config file?

	# __STDLIB_COLOURMAP['type']=$(( ( mode << 16 ) + ( background << 8 ) + foreground ))
	#
	__STDLIB_COLOURMAP['debug']=$(( cyan ))
	__STDLIB_COLOURMAP['error']=$(( red ))
	__STDLIB_COLOURMAP['exec']=$(( magenta ))
	__STDLIB_COLOURMAP['fail']=$(( red ))
	__STDLIB_COLOURMAP['fatal']=$(( ( bold << 16 ) + red ))
	__STDLIB_COLOURMAP['info']=$(( white ))
	__STDLIB_COLOURMAP['note']=$(( blue ))
	__STDLIB_COLOURMAP['okay']=$(( green ))
	__STDLIB_COLOURMAP['warn']=$(( yellow ))

	file="$( std::findfile -app stdlib -name colour.map -dir /etc "${STDLIB_COLOUR_MAP:-}" )"
	if (( 0 == std_ERRNO )) && [[ -s "${file:-}" ]]; then
		section="$( std::getfilesection "${file}" 'colours' | sed 's/#.*$//' | grep -v '^\s*$' )"
		(( std_DEBUG & 2 )) && debug "Read $( wc -l <<<"${section}" ) lines of configuration:"
		(( std_DEBUG & 2 )) && debug "${section}"

		(( std_ERRNO )) && return 1

		for key in debug error exec fail fatal info note okay warn; do
			value="$( grep -m 1 "^\s*${key}\s*=\s*[^[:space:]]\+\s*$" <<<"${section}" | cut -d'=' -f 2- | sed -r 's/\s+//g' )"
			(( std_DEBUG & 2 )) && debug "Read '${value:-}' for key '${key}'"
			if [[ -n "${value:-}" ]]; then
				case "${value}" in
					*,*,*)
						val="$( cut -d',' -f 1 <<<"${value}" )"
						fg=${!val:-}
						val="$( cut -d',' -f 2 <<<"${value}" )"
						bg=${!val:-}
						val="$( cut -d',' -f 3 <<<"${value}" )"
						mode=${!val:-}
						;;
					*,*)
						val="$( cut -d',' -f 1 <<<"${value}" )"
						fg=${!val:-}
						val="$( cut -d',' -f 2 <<<"${value}" )"
						bg=${!val:-}
						mode=0
						;;
					*)
						val="${value}"
						fg=${!val:-}
						bg=$(( default ))
						mode=0
						;;
				esac
				if (( fg )); then
					__STDLIB_COLOURMAP["${key}"]=$(( ( mode << 16 ) + ( bg << 8 ) + fg ))
				fi
			fi
		done
	else
		debug 'Colour-map file not found, using default colours only'
	fi

	# shellcheck disable=2034
	typeset -gix STDLIB_HAVE_COLOUR=1

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
	return 0
} # __STDLIB_oneshot_colours_init # }}}


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
	die 'No override main() function defined'
} # main


# This function may be overridden
#
function __STDLIB_API_1_std::cleanup() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	# N.B.: 'rc' initially contains ${?}, not ${1}
	local -i rc=${?}
	local file

	if [[ -n "${1:-}" ]]; then
		if [[ "${1}" == '0' ]]; then
			rc=${1}; shift
		elif (( ${1} )); then
			rc=${1}; shift
		fi
	fi

	# Remove any STDLIB-generated temporary files and exit.

	for file in "${__STDLIB_OWNED_FILES[@]:-}"; do
		if [[ -n "${file:-}" && -e "${file}" ]]; then

			# TODO: It would be nice to run stdlib.sh functions as
			#       a dedicated unprivileged user by default, so
			#       that cleanup couldn't be maliciously or even
			#       accidentally used to cause system damage if
			#       run by UID 0...

			# XXX: Use std::readlink for cross-platform support...
			if [[ "$( readlink -e "${file}" )" == '/' ]]; then
				die "Attempt made to cleanup/remove '/' - serious bug or malicious code suspected"
			fi

			if rmdir "${file}" >/dev/null 2>&1; then
				(( std_DEBUG & 2 )) && debug "${FUNCNAME[0]##*_} succeeded removing empty directory '${file}'"
			elif rm -f "${file}" >/dev/null 2>&1; then
				(( std_DEBUG & 2 )) && debug "${FUNCNAME[0]##*_} succeeded removing file '${file}'"
			elif rm -rf "${file}" >/dev/null 2>&1; then
				(( std_DEBUG & 2 )) && debug "${FUNCNAME[0]##*_} succeeded removing non-empty file or directory '${file}'"
			else
				warn "${FUNCNAME[0]##*_} unable to remove filesystem object '${file}': ${?}"

				# We'd expect this to fail again, but tell us
				# what happened.  This is arguably less correct
				# than capturing the output in the first place,
				# but the distinction is likely marginal...
				error "$( rm -rv "${file}" 2>&1 )"
				(( rc )) || (( rc++ ))
			fi
		else
			(( std_DEBUG & 2 )) && [[ -n "${file:-}" ]] && debug "${FUNCNAME[0]##*_} unable to remove missing object '${file}'"
		fi
	done
	unset file

	if [[ "${BASH_SOURCE:-${0:-}}" =~ ${std_LIB:-stdlib.sh}$ ]]; then
		trap - EXIT QUIT TERM
	else
		trap - EXIT INT QUIT TERM
	fi
	[[ -n "${__STDLIB_SIGEXIT:-}" ]] && trap ${__STDLIB_SIGEXIT} EXIT
	[[ -n "${__STDLIB_SIGINT:-}" ]] && trap ${__STDLIB_SIGINT} INT
	[[ -n "${__STDLIB_SIGQUIT:-}" ]] && trap ${__STDLIB_SIGQUIT} QUIT
	[[ -n "${__STDLIB_SIGTERM:-}" ]] && trap ${__STDLIB_SIGTERM} TERM

	(( std_x_state )) && set -o xtrace # ... for code trapping exit?

	# 'rc' is numeric, and therefore not subject to word-splitting
	# shellcheck disable=SC2086
	exit ${rc}
} # __STDLIB_API_1_std::cleanup # }}}


# This function should be overridden, or the ${std_USAGE} variable defined
#
function __STDLIB_API_1_usage-message() { # {{{
	warn "${FUNCNAME[0]##*_} invoked - please use 'std::usage-message' instead"

	std::usage-message "${@:-}"
} # __STDLIB_API_1_usage-message # }}}

# Heavyweight compatibility work-around:
declare __STDLIB_usage_message_definition
__STDLIB_usage_message_definition="$( typeset -f usage-message )"
export __STDLIB_usage_message_definition

# This function must be overridden, or the ${std_USAGE} variable defined
#
function __STDLIB_API_1_std::usage-message() { # {{{
	die 'No override std::usage-message() function defined'

	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	# The following output will appear in-line after 'Usage: ${NAME} '...
	output 'Command summary, e.g. "-f|--file <filename> [options]"'
	output <<-\END
Further instructions here, e.g.

	-f : Process the specified <filename>
	-h : Show this help information
	END

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return 0
} # __STDLIB_API_1_std::usage-message # }}}

# This function may be overridden
#
function __STDLIB_API_1_std::usage() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

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

	(( std_x_state )) && set -o xtrace

	# 'rc' is numeric, and therefore not subject to word-splitting
	# shellcheck disable=SC2086
	__STDLIB_API_1_std::cleanup ${rc}
} # __STDLIB_API_1_std::usage # }}}


###############################################################################
#
# stdlib.sh - Standard overridable functions - Logging functions
#
###############################################################################

function __STDLIB_API_1_std::wrap() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local prefix="${1:-}" ; shift
	local text="${*:-}"

	local -i wrap=$(( ${STDLIB_WANT_WORDWRAP:-1} ))

	[[ -n "${prefix}" && -z "${text}" ]] && {
		text="${prefix}"
		prefix=""
	}

	[[ -n "${text:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	# It turns out that working out the width of the current terminal width
	# is remarkably difficult, and differs between various implementations.
	# 'tput cols' is fairly consistent in terms of which OS support it, but
	# doesn't appear to provide a value under non-interactive use.  'stty'
	# is able to output dimensions in a wider range of circumstances, but
	# must be invoked as 'stty --file /dev/stdin' or 'stty -F /dev/stdin'
	# on Linux, but 'stty -f /dev/stdin' on macOS (where the order of
	# arguments is also significant).

	# N.B.: It may be necessary to 'export COLUMNS' before this
	#       works - this variable isn't exported to scripts by default, and
	#       is lost on invocation.

	#local -i columns=${COLUMNS:-$( stty size --file /dev/stdin 2>/dev/null | cut -d' ' -f 2 )}
	local -i columns=${COLUMNS:-$( tput cols 2>/dev/null )}
	if ! (( columns )); then
		# If invoked with a specific indication that word-wrapping is
		# required, then wrap to 80 columns - otherwise, don't wrap at
		# all...
		if [[ -z "${STDLIB_WANT_WORDWRAP:-}" ]]; then
			wrap=0
		else
			columns=80
		fi
	fi

	if [[ -n "${prefix:-}" ]]; then
		# Attempt to sanitise input to sed, which can break in many
		# non-obvious ways...
		prefix="$( LC_ALL=C sed -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/' <<<"${prefix}" )"
		local -l lprefix="${prefix}"

		if (( wrap )) && (( columns > ( ${#prefix} + 2 ) )); then
			  output "${text}" \
			| fold -sw "$(( columns - ( ${#prefix} + 1 ) ))" \
			| sed "s|^|${lprefix} | ; 1{s|^${lprefix}|${prefix}|}"
			std_LASTOUTPUT="$( sed "s|^|${lprefix} | ; 1{s|^${lprefix}|${prefix}|}" <<<"${text}" )"
		else
			  output "${text}" \
			| sed "s|^|${prefix} | ; 1{s|^${lprefix}|${prefix}|}"
			std_LASTOUTPUT="$( sed "s|^|${prefix} | ; 1{s|^${lprefix}|${prefix}|}" <<<"${text}" )"
		fi
	else
		if (( wrap )) && (( columns > 1 )); then
			  output "${text}" \
			| fold -sw "$(( columns - 1))"
		else
			  output "${text}"
		fi
	fi

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return 0
} # __STDLIB_API_1_std::wrap # }}}

function __STDLIB_API_1_std::log() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local prefix="${1:-${std_LIB}}" ; shift
	local data="${*:-}" message

	# Assume that log messages should be written to a file (unless we're
	# debugging) ... otherwise, use note(), warn(), or error() to output
	# to screen.

	if [[ -z "${data:-}" ]]; then
		data="$( cat - )"
	fi
	[[ -n "${data:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	data="$( sed 's/\r//' <<<"${data}" )"

	if [[ "${std_LOGFILE:-}" == 'syslog' ]]; then
		# We'll emulate 'logger -i' here, as we need to return and so
		# can't use 'exec logger' to maintain PID...
		message="[${$}]: ${prefix} ${data}"
		type -pf 'logger' >/dev/null 2>&1 && logger \
			-t "${NAME}" -- "${message}" >/dev/null 2>&1
	fi

	message="${NAME}(${$}) $( date -u +'%Y%m%d %R.%S' ) ${prefix} ${data}"

	# We don't care whether std_LOGFILE exists, but we do care whether it's
	# set...
	[[ -n "${std_LOGFILE:-}" && "${std_LOGFILE}" != 'syslog' ]] \
		&& output "${message}" >>"${std_LOGFILE}" 2>&1

	if (( std_DEBUG )); then
		__STDLIB_API_1_std::wrap "${prefix}" "${data}"
	fi

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return $(( ! std_DEBUG ))
} # __STDLIB_API_1_std::log # }}}

# shellcheck disable=SC2034
function __STDLIB_API_1_std::colour() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local string=""
	local -a text=()
	local -la colour=() type=()
	local -i value2 value1 fg bg mode

	# TODO: Support 16 colours using values 90 (fg-black) to 107 (bg-white)
	#       and 88/256 colour mode using '38;5;<bg>' and '48;5;<fg>' escape
	#       sequences...
	local -i black=0 red=1 green=2 yellow=3 blue=4 magenta=5 cyan=6 white=7
	local -i default=9
	local -i normal=0 bold=1 underline=4 inverse=7

	# Usage: std::colour [-colour <value>] [-type <prefix>] <text [...]>
	local std_PARSEARGS_parsed=0
	eval "$( std::parseargs --single --permissive --var text -- "${@:-}" )"
	if (( std_PARSEARGS_parsed )); then
		set -- "${text[@]:-}"

		if [[ -z "${colour[*]:-}" ]] && [[ -n "${1:-}" ]] && ! [[ "${1}" =~ ^[0-9]+$ ]]; then
			colour=( "${1}" )
			if [[ -z "${!colour:-}" ]]; then
				unset colour
			else
				value2="${!colour}"
				shift
			fi
		fi
	else
		(( std_DEBUG & 2 )) && {
			warn "std::parseargs found no tagged arguments in ${FUNCNAME[0]##*_}:"
			warn "std::parseargs --single --permissive --var text -- '${*:-}'"
		}

		eval "set -- '$( std::parseargs --strip -- "${@:-}" )'"

		if [[ -n "${1:-}" ]] && ! [[ "${1}" =~ ^[0-9]+$ ]]; then
			colour=( "${1}" )
			if [[ -z "${!colour:-}" ]]; then
				unset colour
			else
				value2="${!colour}"
				shift
			fi
		fi
	fi

	[[ -n "${type[*]:-}" || -n "${*:-}" ]] || {
		respond ""

		(( std_x_state )) && set -o xtrace

		# Don't stomp on std_ERRNO
		return 0
	}

	if [[ -z "${STDLIB_WANT_COLOUR:-}" ]] || ! (( STDLIB_WANT_COLOUR )); then
		respond "${*:-}"

		(( std_x_state )) && set -o xtrace

		# Don't stomp on std_ERRNO
		return 0
	fi

	if ! (( ${#__STDLIB_COLOURMAP[@]:-} )); then
		std_ERRNO=$( errsymbol EENV )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	if [[ -n "${colour[*]:-}" ]]; then
		if [[ "${colour[*]}" =~ ^[0-9]+$ ]]; then
			(( value2 = ${colour[*]} ))
		elif [[ -n "${!colour:-}" ]]; then
			value2="${!colour}"
		else
			warn "Unknown colour '${colour[*]}'"
		fi
	fi

	# If we've not been given an explicit type, then try to guess an
	# appropriate value from the first token of the provided message, if
	# any...
	if ! [[ -n "${type[*]:-}" ]]; then
		type=( "${1:-}" )
		type=( "${type// *}" )
	fi
	local -l newtype="${type[*]:-}"
	case "${newtype:-}" in
		exec*)
			type=( 'exec' )
			;;
		info*)
			type=( 'info' )
			;;
		notice*)
			type=( 'note' )
			;;
		ok*)
			type=( 'okay' )
			;;
		warn*)
			type=( 'warn' )
			;;
	esac
	unset newtype
	if [[ -n "${type//[^a-z]}" ]]; then
		type=( "${__STDLIB_COLOURMAP["${type//[^a-z]}"]:-}" )
		if [[ -n "${type[*]:-}" ]]; then
			# type is a prefix from __STDLIB_COLOURMAP, and t is a colour
			# index...
			(( value1 = ${type[*]} ))
		fi
	fi

	# Word-split our arguments, but maintain spacing also...
	string="${*:-}"
	local -a newargs=()
	local char='' word=""
	local -i pos=0 lastspace=0
	for (( pos = 0 ; pos < ${#string} ; pos++ )); do
		char="${string:${pos}:1}"
		if (( lastspace )); then
			if [[ ' ' == "${char}" ]]; then
				word+="${char}"
			else
				lastspace=0
				newargs+=( "${word% }" )
				word="${char}"
			fi
		else
			if [[ ' ' == "${char}" ]]; then
				lastspace=1
			fi
			word+="${char}"
		fi
	done
	if [[ -n "${word:-}" ]]; then
		newargs+=( "${word}" )
	fi
	set -- "${newargs[@]:-}"
	unset lastspace pos word char newargs
	string=""

	if [[ -z "${value1:-}" && -z "${value2:-}" ]]; then
		respond "${*:-}"
	else
		if [[ -n "${value1:-}" ]]; then
			fg=$(( 30 + white )) bg=$(( 40 + default)) mode=$(( normal ))

			string+="\e["

			if (( value1 >= ( 1 << 16 ) )); then
				(( mode = ( value1 >> 16 ) ))
				(( value1 -= ( mode << 16 ) ))
			fi
			if (( value1 >= ( 1 << 8 ) )); then
				(( bg = ( value1 >> 8 ) ))
				(( value1 -= ( bg << 8 ) ))
				(( bg += 40 ))
			fi
			(( fg = 30 + value1 ))

			if (( fg < 30 )) || (( fg > 37 )); then
				warn "Prefix foreground colour index '${fg:-}' out of range {30..37}"
				(( fg = white ))
			fi
			if (( 48 == bg )) || (( bg < 40 )) || (( bg > 49 )); then
				warn "Prefix background colour index '${bg:-}' out of range {40..47,49}"
				(( bg = default ))
			fi
			if ! (( 0 == mode || 1 == mode || 4 == mode || 7 == mode )); then
				warn "Prefix mode index '${mode:-}' out of range {0,1,4,7}"
				(( mode = normal ))
			fi

			if (( bg )); then
				string+="${bg};"
			fi
			if (( fg )); then
				string+="${fg};"
			fi
			if (( mode )); then
				string+="${mode};"
			fi
			string="${string%;}m${1:-}"
			shift

			if [[ -n "${value2:-}" ]] && ! (( value1 == value2 )); then
				string+="\e[0m${*:+ }"
			else
				string+="${*:+ }"
			fi
		fi

		if [[ -n "${value2:-}" && "${value2}" != "${value1:-}" ]]; then
			fg=$(( 30 + white )) bg=$(( 40 + default )) mode=$(( normal ))

			string+="\e["

			if (( value2 >= ( 1 << 16 ) )); then
				(( mode = ( value2 >> 16 ) ))
				(( value2 -= ( mode << 16 ) ))
			fi
			if (( value2 >= ( 1 << 8 ) )); then
				(( bg = ( value2 >> 8 ) ))
				(( value2 -= ( bg << 8 ) ))
				(( bg += 40 ))
			fi
			(( fg = 30 + value2 ))

			if (( fg < 30 )) || (( fg > 37 )); then
				warn "Foreground colour index '${fg:-}' out of range {30..37}"
				(( fg = white ))
			fi
			if (( 48 == bg )) || (( bg < 40 )) || (( bg > 49 )); then
				warn "Background colour index '${bg:-}' out of range {40..47,49}"
				(( bg = default ))
			fi
			if ! (( 0 == mode || 1 == mode || 4 == mode || 7 == mode )); then
				warn "Mode index '${mode:-}' out of range {0,1,4,7}"
				(( mode = normal ))
			fi

			if (( bg )); then
				string+="${bg};"
			fi
			if (( fg )); then
				string+="${fg};"
			fi
			if (( mode )); then
				string+="${mode};"
			fi
			string="${string%;}m"
		fi

		output "${string}${*:-}\e[0m"
	fi

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return 0
} # __STDLIB_API_1_std::colour # }}}

#
# N.B.: To prevent unnecessary indirection, call API-versioned functions below
#

# This function may be overridden
#
function __STDLIB_API_1_die() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	[[ -n "${*:-}" ]] && \
	std_DEBUG=1 __STDLIB_API_1_std::log >&2 "$( __STDLIB_API_1_std::colour 'FATAL: ' )" "${*}"
	__STDLIB_API_1_std::cleanup 1

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return 1
} # __STDLIB_API_1_die # }}}

# This function may be overridden
#
function __STDLIB_API_1_error() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	std_DEBUG=1 __STDLIB_API_1_std::log >&2 "$( __STDLIB_API_1_std::colour 'ERROR: ' )" "${*:-Unspecified error}"

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return 1
} # __STDLIB_API_1_error # }}}

# This function may be overridden
#
function __STDLIB_API_1_warn() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	std_DEBUG=1 __STDLIB_API_1_std::log >&2 "$( __STDLIB_API_1_std::colour 'WARN:  ' )" "${*:-Unspecified warning}"

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return 1
} # __STDLIB_API_1_warn # }}}


# This function may be overridden
#
function __STDLIB_API_1_note() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	std_DEBUG=1 __STDLIB_API_1_std::log     "$( __STDLIB_API_1_std::colour 'NOTICE:' )" "${*:-Unspecified notice}"

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return 0
} # __STDLIB_API_1_note # }}}

function __STDLIB_API_1_notice() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local -i rc=0

	__STDLIB_API_1_note "${@:-}"
	rc=${?}

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return ${rc}
} # __STDLIB_API_1_notice # }}}

# This function may be overridden
#
function __STDLIB_API_1_info() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	std_DEBUG=1 __STDLIB_API_1_std::log     "$( __STDLIB_API_1_std::colour 'INFO:  ' )" "${*:-Unspecified message}"

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return 0
} # __STDLIB_API_1_info # }}}

# This function may be overridden
#
function __STDLIB_API_1_debug() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	(( std_DEBUG )) && \
	            __STDLIB_API_1_std::log >&2 "$( __STDLIB_API_1_std::colour 'DEBUG: ' )" "${*:-Unspecified debug message}"

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return $(( ! std_DEBUG ))
} # __STDLIB_API_1_debug # }}}


###############################################################################
#
# stdlib.sh - Standard functions - errno & friends
#
###############################################################################

function __STDLIB_oneshot_errno_init() { # {{{
	set +o xtrace

	local count=0

	# This function must be called, once, before the errno functions can be
	# used.

	declare -agx __STDLIB_errsym __STDLIB_errstr

	# As per http://tldp.org/LDP/abs/html/exitcodes.html, it would be
	# advantageous if bash code could avoid return values 1, 2, 126-192,
	# and 255.  /usr/include/sysexits.h now defines values in the range 64
	# to 78 - although, as referenced in a footnote, there is no reason to
	# fit around these values since there is no intersection between the
	# code these values apply to and bash scripts.  Additionally, avoiding
	# return codes 1 and 2 is problematic for interoperability with
	# existing code.  Avoiding return codes which are not positive integers
	# appears to be problematic for Java prorgammers ;)
	#
	# It is reasonable to return 1 and set a descriptive/diagnostic
	# std_ERRNO on failure.

	# TODO: This should really be sourced from an external config file.
	#

	# 0 is not a real error code, but it is useful to have a placeholder
	# here...
	__STDLIB_errsym[0]='ENOERROR'		; __STDLIB_errstr[0]='Operation successful'			; (( count ++ )) ;

	# Named error conditions - these should always be referred to by symbol
	# rather than by number (other than in the internal errno functions,
	# which can't rely on all values below being fully initialised).
	__STDLIB_errsym[1]='ENOTFOUND'		; __STDLIB_errstr[1]='Parameter value not found'		; (( count ++ )) ;
	__STDLIB_errsym[2]='EENV'		; __STDLIB_errstr[2]='Invalid environment'			; (( count ++ )) ;
	__STDLIB_errsym[3]='EARGS'		; __STDLIB_errstr[3]='Invalid arguments'			; (( count ++ )) ;
	__STDLIB_errsym[4]='ENOEXE'		; __STDLIB_errstr[4]='Required executable not found'		; (( count ++ )) ;
	__STDLIB_errsym[5]='ESYNTAX'		; __STDLIB_errstr[5]='Syntax error'				; (( count ++ )) ;
	__STDLIB_errsym[6]='EACCESS'		; __STDLIB_errstr[6]='File access denied'			; (( count ++ )) ;

	# These should appear, in order, last:
	__STDLIB_errsym[ ${count} ]='EERROR'	; __STDLIB_errstr[ ${count} ]='Undefined error'			; (( count ++ )) ;
	__STDLIB_errsym[ ${count} ]='ENOTSET'	; __STDLIB_errstr[ ${count} ]='Logic failure: errno unset'	; # Final item, no increment

	declare -gix __STDLIB_errtotal="${count}" std_ERRNO=0 STDLIB_HAVE_ERRNO=1

	return 0
} # __STDLIB_oneshot_errno_init # }}}

function __STDLIB_API_1_symerror() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local -i err="${1:-${std_ERRNO:-0}}"

	# Given an error number, provide the associated symbolic error name.

	if (( __STDLIB_errtotal < 1 || ! STDLIB_HAVE_ERRNO )); then
		# FIXME: Obsolete
		error "errno not initialised - please re-import ${std_LIB}" \
		      "with 'STDLIB_WANT_ERRNO' set"

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	if (( err >= 0 && err <= ${__STDLIB_errtotal:-0} )) && [[ -n "${__STDLIB_errsym[ ${err} ]:-}" ]]; then
		respond "${__STDLIB_errsym[ ${err} ]}"

		(( std_x_state )) && set -o xtrace

		return 0
	fi

	std_ERRNO=1 # instead use 'std_ERRNO=$( errsymbol ENOTFOUND )'

	(( std_x_state )) && set -o xtrace

	return 1
} # __STDLIB_API_1_symerror # }}}

function __STDLIB_API_1_errsymbol() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local symbol="${1:-}"
	local -i n

	# Given a symbolic error name, provide the error number (to set
	# std_ERRNO, for example).

	if (( __STDLIB_errtotal < 1 || ! STDLIB_HAVE_ERRNO )); then
		# FIXME: Obsolete
		error "errno not initialised - please re-import ${std_LIB}" \
			"with 'STDLIB_WANT_ERRNO' set"

		(( std_x_state )) && set -o xtrace

		return 1
	fi
	if [[ -z "${symbol:-}" ]]; then
		std_ERRNO=3 # instead use 'std_ERRNO=$( errsymbol EARGS )'

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	for n in $( seq 0 $(( ${__STDLIB_errtotal:-0} )) ); do
		if [[ "${symbol}" == "${__STDLIB_errsym[ ${n} ]:-}" ]]; then
			respond "${n}"

			(( std_x_state )) && set -o xtrace

			return 0
		fi
	done

	std_ERRNO=1 # instead use 'std_ERRNO=$( errsymbol ENOTFOUND )'

	(( std_x_state )) && set -o xtrace

	return 1
} # __STDLIB_API_1_errsymbol # }}}

function __STDLIB_API_1_strerror() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local err="${1:-${std_ERRNO:-}}" ; shift
	local msg='Unknown error number' rc=1

	# Given an error number, provide the associated error string.

	if (( __STDLIB_errtotal < 1 || ! STDLIB_HAVE_ERRNO )); then
		# FIXME: Obsolete
		error "errno not initialised - please re-import ${std_LIB}" \
			"with 'STDLIB_WANT_ERRNO' set"

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	if [[ "${err:-}" =~ ^[0-9]+$ ]] && [[ -n "${__STDLIB_errstr[ ${err} ]:-}" ]]; then
		msg="${__STDLIB_errstr[ ${err} ]}"
		rc=0
	fi

	respond "${msg}"

	(( std_x_state )) && set -o xtrace

	return ${rc}
} # __STDLIB_API_1_strerror # }}}


###############################################################################
#
# stdlib.sh - Standard functions - mktemp & friends
#
###############################################################################

function __STDLIB_API_1_std::garbagecollect() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local file=""
	local -i rc=0

	# Add an additional file to the list of files to be removed when
	# std::cleanup is invoked.
	# This can be used to work-around the use of std::mktemp in a
	# sub-shell.

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
	for file in "${@:-}"; do
		if [[ -e "${file}" ]]; then
			__STDLIB_OWNED_FILES+=( "${file}" )
			rc=${rc:-0}
		else
			std_ERRNO=$( errsymbol ENOTFOUND )
			rc=1
		fi
	done

	if (( std_DEBUG & 2 )); then
		if ! [[ -n "${__STDLIB_OWNED_FILES[*]:-}" ]]; then
			warn "${FUNCNAME[0]##*_} is not tracking any files after being invoked with filenames '${*:-}'"
		else
			debug "${FUNCNAME[0]##*_} now tracking ${#__STDLIB_OWNED_FILES[@]} files:"
			for file in "${__STDLIB_OWNED_FILES[@]}"; do
				debug "${std_TAB}${file}"
			done
		fi
	fi

	(( std_x_state )) && set -o xtrace

	# std_ERRNO set above
	return ${rc:-1}
} # __STDLIB_API_1_std::garbagecollect # }}}

function __STDLIB_API_1_std::mktemp() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local -a tmpdir=() suffix=() directory=() files=()
	local -i namedargs=1

	# Usage: std::mktemp [-directory] [-tmpdir <directory>] _
	#        [-suffix <extension>] [filename_component ...]
	local std_PARSEARGS_parsed=0
	eval "$( std::parseargs --single --permissive --var files -- "${@:-}" )"
	(( std_PARSEARGS_parsed )) || {
		(( std_DEBUG & 2 )) && {
			warn "std::parseargs found no tagged arguments in ${FUNCNAME[0]##*_}:"
			warn "std::parseargs --single --permissive --var files -- '${*:-}'"
		}

		eval "set -- '$( std::parseargs --strip -- "${@:-}" )'"
		files=( "${@:-}" )
		namedargs=0
	}

	local message standard opts

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
	#
	# ... and in typical fashion, MacOS has a BSD mktemp which offers
	# fewer features.  In this case, no suffix is possible, and we can
	# either specify a prefix (that will have 8 random characters appended)
	# which will be placed into ${TMPDIR} with '-t', or provide a full path
	# and template if no option is given.
	#
	# (Un)helpfully, the non-GNU mktemp returns an error if you try to find
	# out what it is, which we can then take advantage of thusly:
	#
	local -i __std_mktemp_standard_gnu=1 __std_mktemp_standard_legacy=2 __std_mktemp_standard_bsd=4
	readonly __std_mktemp_standard_gnu __std_mktemp_standard_legacy __std_mktemp_standard_bsd
	mktemp --version >/dev/null 2>&1
	case ${?} in
		0)
			message='GNU mktemp failed'
			standard=$__std_mktemp_standard_gnu
			;;
		1)
			[[ -n "${suffix[*]:-}" ]] && debug "${FUNCNAME[0]##*_} Removing" \
				"unsupported 'suffix' option with non-GNU system mktemp"
			unset suffix
			message='legacy/BSD mktemp failed'
			case "$( uname -s )" in
				Linux)
					standard=$__std_mktemp_standard_legacy
					;;
				*)
					standard=$__std_mktemp_standard_bsd
					;;
			esac
			;;
		*)
			die "Cannot detect mktemp version: ${?}"
			;;
	esac

	if [[ "${directory[*]:-}" == '__DEFINED__' ]]; then
		opts='-d '
	fi

	if (( 0 == namedargs )); then
		if [[ -n "${1:-}" && -d "${1}" ]]; then
			tmpdir=( "${1}" )
			shift
		fi
	fi
	if [[ -d "${tmpdir[0]:-}" ]]; then
		case ${standard} in
			$__std_mktemp_standard_gnu)
				# Note trailing space and quote...
				opts+="--tmpdir=\"${tmpdir[0]}\" \""
				;;
			$__std_mktemp_standard_legacy)
				# Note lack of trailing space before quote...
				opts+="\"${tmpdir[0]}\"/\""
				;;
			$__std_mktemp_standard_bsd)
				# There are two options here:
				# 'mktemp -t file' acts like
				# 'mktemp "${TMPDIR}"/file.XXXXXXXX', but can't
				# accept paths or templates;
				# 'mktemp "${TMPDIR}"/file.XXXXXXXX' expands
				# specified templates.
				# Note lack of trailing space before quote...
				opts+="\"${tmpdir[0]}\"/\""
				;;
		esac
	else
		tmpdir=( "${TMPDIR:-/tmp}" )

		case ${standard} in
			$__std_mktemp_standard_bsd)
				opts+="\"${tmpdir[0]}\"/\""
				;;
			*)
				# Note trailing space and quote...
				opts+='-t "'
				;;
		esac
	fi

	local -a __std_NEWFILES
	local file name

	[[ -n "${files[*]:-}" ]] || files=( "${NAME%.sh}" )
	for file in "${files[@]}"; do
		name="${file}.XXXXXXXX${suffix[*]:+.${suffix[*]}}"

		# Otherwise undocumented, **POTENTIALLY DANGEROUS**, configuration setting...
		if [[ -n "${STDLIB_REUSE_TEMPFILES:-}" ]]; then
			local filename
			filename="$( find "${tmpdir[0]}" -mindepth 1 -maxdepth 1 -name "${NAME%.sh}.${file}.*" -print 2>/dev/null | tail -n 1 )"

			if [[ -n "${filename:-}" && -w "${filename}" ]]; then
				[[ " ${__STDLIB_OWNED_FILES[*]} " =~ \ ${filename}\  ]] ||
					__STDLIB_OWNED_FILES+=( "${filename}" )

				cat /dev/null > "${filename}" 2>/dev/null
				respond "${filename}"

				unset filename

				continue
			fi
		fi

		(( std_DEBUG & 2 )) && debug "Creating temporary object with 'mktemp ${opts}${name}\"'"
		__std_NEWFILES+=(
			"$( eval "mktemp ${opts}${name}\"" || {
				error "${message}"

				std_ERRNO=$( errsymbol EERROR )

				(( std_x_state )) && set -o xtrace

				return 1
			} )"
		)
	done

	if [[ -n "${__std_NEWFILES[*]:-}" ]]; then
		__STDLIB_OWNED_FILES+=( "${__std_NEWFILES[@]}" )

		for file in "${__std_NEWFILES[@]}"; do
			respond "${file}"
		done

		if (( std_DEBUG & 2 )); then
			if ! [[ -n "${__STDLIB_OWNED_FILES[*]:-}" ]]; then
				warn "${FUNCNAME[0]##*_} is not tracking any files after attempting to register filenames '${__std_NEWFILES[*]}'"
			else
				debug "${FUNCNAME[0]##*_} now tracking ${#__STDLIB_OWNED_FILES[@]} files:"
				for file in "${__STDLIB_OWNED_FILES[@]}"; do
					debug "${std_TAB}${file}"
				done
			fi
		fi
	fi

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return 0
} # __STDLIB_API_1_std::mktemp # }}}

function __STDLIB_API_1_std::emktemp() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local -a var=() tmpdir=() suffix=() directory=() names=()

	# Usage: std::emktemp -var <variable> [-directory] _
	#        [-tmpdir <directory>] [-suffix <extension>] _
	#        [filename_component ...]
	local std_PARSEARGS_parsed=0
	eval "$( std::parseargs --single --permissive --var names -- "${@:-}" )"
	if (( std_PARSEARGS_parsed )); then
		(( std_DEBUG & 2 )) && {
			warn "std::parseargs found no tagged arguments in ${FUNCNAME[0]##*_}:"
			warn "std::parseargs --single --permissive --var names -- '${*:-}'"
		}

		set -- "${names[@]:-}"

		if [[ -z "${var[0]:-}" ]]; then
			var=( "${1}" ) ; shift
		fi
	else
		eval "set -- '$( std::parseargs --strip -- "${@:-}" )'"
		var=( "${1}" ) ; shift
	fi

	[[ -n "${var[0]:-}" ]] || {
		error "${FUNCNAME[0]##*_} requires at least one argument"

		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}
	if ! [[ "${var[0]}" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
		error "${FUNCNAME[0]##*_} parameter-name '${var[0]}' is not a valid variable-name"

		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

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

	local file rc
	local -a files=() results=()
	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	files=( $( eval "__STDLIB_API_1_std::mktemp ${directory[0]:+-directory} ${tmpdir[0]:+-tmpdir "${tmpdir[*]}"} ${suffix[0]:+-suffix "${suffix[*]}"} ${*:-${NAME%.sh}}" ) )
	rc=${?}

	if (( rc )); then
		# std_ERRNO set by __STDLIB_API_1_std::mktemp

		(( std_x_state )) && set -o xtrace

		return ${rc}
	else
		for file in "${files[@]:-}"; do
			__STDLIB_API_1_std::garbagecollect "${file}" \
				&& results+=( "${file}" ) \
				|| rc=1
		done
	fi
	if [[ -n "${results[*]:-}" ]]; then
		eval "export ${var[0]}='${results[*]}'"
	else
		rc=1
	fi

	(( std_x_state )) && set -o xtrace

	# std_ERRNO set by __STDLIB_API_1_std::garbagecollect
	return ${rc}
} # __STDLIB_API_1_std::emktemp # }}}


###############################################################################
#
# stdlib.sh - 'Push' from https://github.com/vaeth/push
#
###############################################################################

function __STDLIB_API_1_std::push() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local std_push_result='' std_push_var std_push_current std_push_segment std_push_arg std_push_add_quote=""
	local -i rc=0

	# Martin Väth's original push.sh states that "This project is under the
	# BSD license", but otherwise includes no further terms or indeed any
	# licence text.
	# The BSD licence requires that the licence text itself be included
	# with any code it covers, so the actual situation is ... unclear, at
	# best.  It would appear that the spirit of the BSD licence is met by
	# including Martin's licensing statement, as above.

	# "Treat a variable like an array, quoting args"
	#
	# Usage: std::push [-c] VARIABLE [arguments]
	#
	# -c : clear VARIABLE before adding [arguments]
	#
	# The arguments will be appended to VARIABLE in a quoted manner (with
	# quotes rarely used - the exact form depends on the version of the
	# script) so that an "eval" $VARIABLE obtains the collected arguments
	#
	# The first call for VARIABLE must always include '-c'
	# The return value will be zero if $VARIABLE contains at least one
	# push()ed argument
	#
	# e.g.
	#
	# $ std::push -c text 'data with symbols such as ()"\' "'another arg'"
	# $ std::push text further args
	# $ eval "printf '%s\\n' ${text}"
	# data with symbols such as ()"\
	# 'another arg'
	# further
	# args
	#
	# Remove the last argument from the argument list in a script:
	# $ std::push -c args
	# $ while [ ${#} -gt 1 ]
	# > do std::push args "${1}"
	# > shift
	# > done
	# $ eval "set -- x ${args}" ; shift # x is shifted out, but prevents
	#                                   # Bourne sh from breaking...
	#
	# Quote a command for use with 'su' (even if it contains spaces, '<',
	# or quotes):
	# $ std::push -c files "${@}" && su -c "cat -- ${files}"
	#
	# Pretty-print a command:
	# $ set -- source~1 'source 2# "source '3'"
	# $ std::push -c v cp -- "${@}" \~dest
	# $ printf '%s\n' "${v}"
	# cp -- source~1 'source 2' 'source '\'3\' '~dest'
	#
	# Test whether a variable is set:
	# $ std::push -c data
	# $ myfunction
	# $ std::push data || echo 'Nothing was added to $data by myfunction()'
	#

	# ... one of the most obfuscated shell functions I've ever come across!

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
		#       Is it solely a special-case for referencing
		#       home-directories?
		#
		unset std_push_add_quote
		#case "${std_push_arg:-=}" in
		#	[=~]*)
		#		std_push_add_quote='yes'
		#		;;
		#esac
		[[ "${std_push_arg:-}" =~ ^[=~] ]] && std_push_add_quote='yes'

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

	(( std_DEBUG & 2 )) && debug " std_push_var='${std_push_var}', value=|$( eval echo "\"\${${std_push_var}:-}\"" )|, rc=${rc}"

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
	(( rc )) && std_ERRNO=$( errsymbol EERROR )

	(( std_x_state )) && set -o xtrace

	return ${rc}
} # __STDLIB_API_1_std::push # }}}


###############################################################################
#
# stdlib.sh - Standard functions - Platform-neutral readlink
#
###############################################################################

function __STDLIB_API_1_std::readlink() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local file="${1:-}" ; shift
	local -i rc=0

	[[ -n "${file:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	# Find the target of a symlink, in circumstances where GNU readlink is
	# not available

	# TODO: Implement GNU arguments...
	#
	# GNU readlink manpage states:
	#       Print value of a symbolic link or canonical file name
	#
	#       -f, --canonicalize
	#              canonicalize by following every symlink in every
	#              component of the given name recursively; all but the
	#              last component must exist
	#
	#       -e, --canonicalize-existing
	#              canonicalize by following every symlink in every
	#              component of the given name recursively, all components
	#              must exist
	#
	#       -m, --canonicalize-missing
	#              canonicalize by following every symlink in every
	#              component of the given name recursively, without
	#              requirements on components existence
	#
	#       -n, --no-newline
	#              do not output the trailing delimiter
	#
	#       -q, --quiet
	#
	#       -s, --silent
	#              suppress most error messages
	#
	#       -v, --verbose
	#              report error messages
	#
	#       -z, --zero
	#              end each output line with NUL, not newline
	#

	if type -pf 'perl' >/dev/null 2>&1; then
		if perl -MCwd=abs_path </dev/null >/dev/null 2>&1; then
			respond "$( perl -MCwd=abs_path -le 'print abs_path readlink(shift);' "${file}" )"

			std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

			(( std_x_state )) && set -o xtrace

			return 0
		fi
	fi

	# FIXME: The code below doesn't handle loops - import code and/or tests
	#        from https://github.com/mkropat/sh-realpath/?
	local result
	result="$(
		cd "$( dirname -- "${file}" )" || exit 1
		file="$( basename -- "${file}" )"

		while [[ -L "${file}" ]]; do
			file="$( readlink -- "${file}" )"
			cd "$( dirname -- "${file}" )" || exit 1
			file="$( basename -- "${file}" )"
		done

		local dir
		dir="$( pwd -P )"
		respond "${dir:-}"/"${file}"
	)"
	rc=${?}

	if (( ! rc )) && [[ -n "${result:-}" ]]; then
		respond "${result}"

		std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

		(( std_x_state )) && set -o xtrace

		return 0
	else
		std_ERRNO=$( errsymbol ENOTFOUND )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	# Unreachable
	std_ERRNO=$( errsymbol EERROR )

	(( std_x_state )) && set -o xtrace

	return 255
} # __STDLIB_API_1_std::readlink # }}}


###############################################################################
#
# stdlib.sh - Standard functions - Document the use of global variables
#
###############################################################################

function __STDLIB_API_1_std::inherit() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local var item skip parent name
	local -i exported=0
	local -a val=() flags=()

	# Usage:
	#
	# eval std::inherit [-ex] [--] VARIABLE 0
	#
	# Explicitly indicates that the current function will make use of
	# global variable VARIABLE, and initialise VARIABLE to contain the
	# optional second argument if no global value is set.
	# The -e flag specifies that VARIABLE must be exported rather than
	# simply set, and the -x flag specifies that VARIABLE will be exported
	# if it does not exist.
	# Other than -e, the valid flags are those used by declare/typeset.
	#
	# The v2 definition of this function, below, extends std::inherit() to
	# accept a list of key/value pairs rather than operating on only a
	# single variable at once.

	for item in "${@:-}"; do
		if [[ "${item}" == '--' ]]; then
			skip='skip'
		elif [[ -z "${skip:-}" && "${item}" =~ ^-[eaAilnrtux]+$|^\+[ilntux]+$ ]]; then
			if [[ "${item}" =~ e ]]; then
				exported=1
				item="${item//e}"
			fi
			flags+=( "${item}" )
		elif [[ -z "${val[*]:-}" ]]; then
			var="${item}"
		else
			val+=( "${item}" )
		fi
	done

	[[ -n "${var:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	if ! [[ "${var}" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
		error "${FUNCNAME[0]##*_} parameter-name '${var}' is not a valid variable-name"

		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	if [[ -n "${FUNCNAME[0]:-}" ]]; then
		name="${FUNCNAME[0]/__STDLIB_API_[0-9]_}"
		[[ -n "${name:-}" ]] || {
			std_ERRNO=$( errsymbol EENV )

			(( std_x_state )) && set -o xtrace

			return 1
		}

		parent="${FUNCNAME[1]:-}"
		[[ "${parent:-}" == "${name}" ]] && parent="${FUNCNAME[2]:-}"
	fi
	if [[ -z "${parent:-}" ]]; then
		output >&2 "${SHELL:-bash}: ${name:-std::inherit}: can only be used in a function"

		std_ERRNO=$( errsymbol ESYNTAX )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	if (( exported )) && env | grep -q "^${var}="; then
		:
	elif (( ! exported )) && [[ -n "${!var:-}" ]]; then
		:
	else
		[[ -n "${val[*]:-}" ]] || {
			std_ERRNO=$( errsymbol ENOTFOUND )

			(( std_x_state )) && set -o xtrace

			return 1
		}

		respond "declare ${flags[*]:-} ${skip:+--} ${var}=$( declare -p val | cut -d'=' -f 2- )"
	fi

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return 0
} # __STDLIB_API_1_std::inherit # }}}

function __STDLIB_API_2_std::inherit() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local item skip parent name value
	local -i shouldexport=0 rc=0
	local -a var=() flags=()
	local -A val=()

	# Usage:
	#
	# eval std::inherit [-ex] [--] VARIABLE[=VALUE] [VAR2[=VAL2] ...]
	#
	# Explicitly indicates that the current function will make use of
	# global variable VARIABLE, and initialise VARIABLE to contain the
	# optional second argument if no global value is set.
	# The -e flag specifies that VARIABLE must be exported rather than
	# simply set, and the -x flag specifies that VARIABLE will be exported
	# if it does not exist.
	# Other than -e, the valid flags are those used by declare/typeset.

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	for item in "${@:-}"; do
		if [[ "${item}" == '--' ]]; then
			skip='skip'
		elif [[ -z "${skip:-}" && "${item}" =~ ^-[eaAilnrtux]+$|^\+[ilntux]+$ ]]; then
			if [[ "${item}" =~ e ]]; then
				shouldexport=1
				item="${item//e}"
			fi
			flags+=( "${item}" )
		else
			if [[ "${item}" =~ ^= ]]; then
				error "${FUNCNAME[0]##*_} parameter '${item}' is not a valid variable name"

				std_ERRNO=$( errsymbol EARGS )
				rc=1
			fi

			name="$( cut -d'=' -f 1 <<<"${item}" )"
			[[ "${item}" =~ = ]] && value="$( cut -d'=' -f 2- <<<"${item}" )"

			if ! [[ "${name}" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
				error "${FUNCNAME[0]##*_} parameter '${name}' is not a valid variable name"

				std_ERRNO=$( errsymbol EARGS )
				rc=1
			fi

			if grep -q " ${name} " <<<" ${var[*]:-} "; then # ` # <- Ubuntu syntax highlight fail
				error "${FUNCNAME[0]##*_} parameter '${name}' is specified multiple times"

				std_ERRNO=$( errsymbol EARGS )
				rc=1
			else
				var+=( "${name}" )
				if [[ -n "${value:-}" ]]; then
					val[${name}]="${value}"
				fi
			fi
		fi
	done

	[[ -n "${#var[@]:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	if [[ -n "${FUNCNAME[0]:-}" ]]; then
		name="${FUNCNAME[0]/__STDLIB_API_[0-9]_}"
		[[ -n "${name:-}" ]] || {
			std_ERRNO=$( errsymbol EENV )

			(( std_x_state )) && set -o xtrace

			return 1
		}

		parent="${FUNCNAME[1]:-}"
		[[ "${parent:-}" == "${name}" ]] && parent="${FUNCNAME[2]:-}"
	fi
	if [[ -z "${parent:-}" ]]; then
		output >&2 "${SHELL:-bash}: ${name:-std::inherit}: can only be used in a function"

		std_ERRNO=$( errsymbol ESYNTAX )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	for name in "${var[@]}"; do
		if (( shouldexport )) && env | grep -q "^${name}="; then
			:
		elif (( ! shouldexport )) && [[ -n "${!name:-}" ]]; then
			:
		else
			value="${val[${name}]:-}"
			if [[ -n "${value:-}" ]]; then
				respond "declare ${flags[*]:-} ${skip:+--} ${name}=$( declare -p 'value' | cut -d'=' -f 2- )"
				(( shouldexport )) && respond "export ${name}"
			else
				std_ERRNO=$( errsymbol ENOTFOUND )
				rc=1
			fi
		fi
	done

	(( std_x_state )) && set -o xtrace

	return ${rc}
} # __STDLIB_API_2_std::inherit # }}}


###############################################################################
#
# stdlib.sh - Standard functions - Improved HEREDOC support
#
###############################################################################

function __STDLIB_API_1_std::define() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	# This is not the same variable previously declared to be an array...
	# shellcheck disable=SC2178
	local var="${1:-}" ; shift
	local state ifs value

	# Usage:
	#
	# std::define VARIABLE <<'EOF'
	# heredoc content to be read into $VARIABLE without using 'cat'
	# You can 'quote ""things as you like...
	# ... $( and this won't be executed )!
	# EOF
	#
	# Please note that leading and trailing spaces are eaten by bash!  In
	# order to handle these cases, please add a leading and/or trailing
	# guard sequence - for implementation details, please see the parseargs
	# tests in stdlib's test.sh where the character 'x' is used for such a
	# purpose...

	[[ -n "${var:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	# Don't expand asterisks, and don't exit when read returns non-zero on
	# hitting EOF...
	state="$( set +o | grep -E '(noglob|errexit)$' )"
	set -f
	set +e
	ifs="${IFS:-}"
	IFS=$'\n' # Loses leading and trailing blank lines :(

	# This is not the same variable previously declared to be an array...
	# shellcheck disable=SC2128
	read -r -d '' "${var}"

	IFS="${ifs:-}"
	eval "${state}"

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	if [[ -z "${var:-}" ]]; then
		# Don't change std_ERRNO

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	(( std_x_state )) && set -o xtrace

	return 0
} # __STDLIB_API_1_std::define # }}}


###############################################################################
#
# stdlib.sh - Standard functions - Prepare a list of items for pretty-printing
#
###############################################################################

function __STDLIB_API_1_std::formatlist() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local item

	if [[ -n "${3:-}" ]]; then
		item="${1:-}" ; shift
		respond "${item:-}, $( ${FUNCNAME[0]##*_} "${@:-}" )"
	elif [[ -n "${2:-}" ]]; then
		if [[ -n "${FUNCNAME[1]:-}" && "${FUNCNAME[1]##*_}" == "${FUNCNAME[0]##*_}" ]]; then
			respond "${1:-}, and ${2:-}"
		else
			respond "${1:-} and ${2:-}"
		fi
	else
		respond "${*:-}"
	fi

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return 0
} # __STDLIB_API_1_std::formatlist # }}}


###############################################################################
#
# stdlib.sh - Standard functions - Handle version-strings in a standard way
#
###############################################################################

function __STDLIB_API_1_std::vcmp() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local vone op vtwo list

	# Does system 'sort' have version-sort capability (again, CentOS/Red
	# Hat seem to lose out here...)
	sort --version-sort </dev/null || {
		std_ERRNO=$( errsymbol ENOEXE )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	if ! (( 3 == ${#} )); then
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	vone="${1:-}"
	op="${2:-}"
	vtwo="${3:-}"

	case "${op:-}" in
		'<'|lt|-lt)
			if [[ "${vone}" != "${vtwo}" && "$( echo -e "${vone}\n${vtwo}" | sort -V 2>/dev/null | head -n 1 )" == "${vone}" ]]; then
				(( std_x_state )) && set -o xtrace

				# vone < vtwo
				return 0
			else
				(( std_x_state )) && set -o xtrace

				# vone !< vtwo
				return 1
			fi
			;;
		'<='|le|-le)
			if [[ "${vone}" == "${vtwo}" || "$( echo -e "${vone}\n${vtwo}" | sort -V 2>/dev/null | head -n 1 )" == "${vone}" ]]; then
				(( std_x_state )) && set -o xtrace

				# vone <= vtwo
				return 0
			else
				(( std_x_state )) && set -o xtrace

				# vone > vtwo
				return 1
			fi
			;;
		'>'|gt|-gt)
			if [[ "${vone}" != "${vtwo}" && "$( echo -e "${vone}\n${vtwo}" | sort -V 2>/dev/null | tail -n +2 )" == "${vone}" ]]; then
				(( std_x_state )) && set -o xtrace

				# vone > vtwo
				return 0
			else
				(( std_x_state )) && set -o xtrace

				# vone !> vtwo
				return 1
			fi
			;;
		'>='|ge|-ge)
			if [[ "${vone}" == "${vtwo}" || "$( echo -e "${vone}\n${vtwo}" | sort -V 2>/dev/null | tail -n +2 )" == "${vone}" ]]; then
				(( std_x_state )) && set -o xtrace

				# vone >= vtwo
				return 0
			else
				(( std_x_state )) && set -o xtrace

				# vone < vtwo
				return 1
			fi
			;;
		*)
			list="$(
				local version
				for version in "${@:-}"; do
					echo "${version:-}"
				done | sort -V 2>/dev/null
			)"
			respond "${list}"
			if [[ "$( echo "${list}" | xargs echo )" == "$( echo "${*:-}" | xargs echo )" ]]; then
				(( std_x_state )) && set -o xtrace

				return 0
			else
				(( std_x_state )) && set -o xtrace

				return 1
			fi
			;;
	esac

	# Unreachable
	std_ERRNO=$( errsymbol EERROR )

	(( std_x_state )) && set -o xtrace

	return 255
} # __STDLIB_API_1_std::vcmp # }}}


###############################################################################
#
# stdlib.sh - Standard functions - Ensure that needed binaries are present
#
###############################################################################

function __STDLIB_API_1_std::requires() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local item location
	local -i shouldexit=1 quiet=1 path=0 rc=0
	local -a files=()

	for item in "${@:-}"; do
		if [[ "${item:-}" =~ ^(--)?(no-?exit|no-?abort|keep|keep-?going)$ ]]; then
			shouldexit=0
		elif [[ "${item:-}" =~ ^(--)?no-?quiet$ ]]; then
			quiet=0
		elif [[ "${item:-}" =~ ^(--)?path$ ]]; then
			path=1
		elif [[ "${item:-}" =~ ^-- ]]; then
			debug "Unknown argument '${item}' to ${FUNCNAME[0]##*_}"
		elif [[ -n "${item:-}" ]]; then
			files+=( "${item}" )
		fi
	done

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	if ! (( ${#files[@]} )); then
		std_ERRNO=3 # instead use 'std_ERRNO=$( errsymbol EARGS )'

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	for item in "${files[@]:-}"; do
		if location="$( type -pf "${item:-}" 2>/dev/null )"; then
			(( path )) && respond "${location:-}"
		else
			if ! (( quiet )); then
				if [[ "$( type -t 'error' 2>/dev/null )" == 'function' ]]; then
					error "Cannot locate required '${item:-}' binary"
				else
					echo >&2 "ERROR:  Cannot locate required '${item:-}' binary"
				fi
			fi
			std_ERRNO=1 # instead use 'std_ERRNO=$( errsymbol ENOTFOUND )'
			rc=1
		fi
	done

	(( shouldexit )) && (( rc )) && __STDLIB_API_1_std::cleanup 1

	(( std_x_state )) && set -o xtrace

	# std_ERRNO set above
	return ${rc}
} # __STDLIB_API_1_std::requires # }}}

__STDLIB_API_1_std::requires --no-quiet --no-abort basename cat cut dirname grep readlink sed sort uniq || exit 1


###############################################################################
#
# stdlib.sh - Helper functions - Capture output of commands
#
###############################################################################

function __STDLIB_API_1_std::capture() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local stream="${1:-}" ; shift
	local cmd="${1:-}" ; shift
	local args=( "${@:-}" )
	local redirect="" response="" stdbuf=""
	local -i rc=0

	# Return the stdout or stderr output of a command in a consistent way.

	case "${stream:-}" in
		1|out|stdout)
			redirect='2>/dev/null'
			;;
		2|err|stderr)
			# N.B.: Ordering - ensure we still get stderr on &1
			redirect='2>&1 >/dev/null'
			;;
		all|both)
			redirect='2>&1'
			;;
		none)
			redirect='>/dev/null 2>&1'
			;;
		*)
			error "Invalid parameters: prototype '${FUNCNAME[0]##*_}" \
				"<stream> <command> [arguments]', received" \
				"'<${stream:-}> <${cmd:-}> [${args[*]}]'"
			std_ERRNO=$( errsymbol EARGS )

			(( std_x_state )) && set -o xtrace

			return 1
			;;
	esac

	if ! type -t "${cmd:-}" >/dev/null; then
		error "Invalid parameters: <command> '${cmd:-}' not found"
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	type -pf 'stdbuf' >/dev/null 2>&1 && stdbuf='stdbuf -eL'

	response="$( eval "${stdbuf:+${stdbuf} }${cmd} ${args[*]} ${redirect}" )" ; rc=${?}
	output "${response:-}"

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return ${rc}
} # __STDLIB_API_1_std::capture # }}}

function __STDLIB_API_1_std::ensure() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local err="${1:-}" ; shift
	local cmd="${1:-}" ; shift
	local args=( "${@:-}" )
	local response=""
	local -i rc=0

	# If we're given an error message, silently succeed or fail with the
	# specified message; if we don't have an error message then output a
	# valid response or the command's failure text.

	if ! type -t "${cmd:-}" >/dev/null; then
		error "Invalid parameters: <command> '${cmd:-}' not found"

		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	fi

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
	response="$( __STDLIB_API_1_std::capture stderr "${cmd}" "${args[@]}" )" ; rc=${?}
	if (( !( rc ) )); then
		# Succeeded
		[[ -z "${err:-}" ]] && output "${response:-}"

		(( std_x_state )) && set -o xtrace

		# Don't stomp on std_ERRNO
		return ${rc}
	else
		# Failed

		die "${err:-${response:-}}"
	fi

	# Unreachable
	std_ERRNO=$( errsymbol EERROR )

	(( std_x_state )) && set -o xtrace

	return 255
} # __STDLIB_API_1_std::ensure # }}}

function __STDLIB_API_1_std::silence() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	[[ -n "${1:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	__STDLIB_API_1_std::capture all "${@:-}" >/dev/null

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return ${?}
} # __STDLIB_API_1_std::silence # }}}


###############################################################################
#
# stdlib.sh - Helper functions - Safely split whitespace-separated strings
#
###############################################################################

function __STDLIB_API_1_std::wordsplit() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local -a string="${*:-}" words
	local word

	[[ -n "${string:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	read -r -d '' -a words <<<"${string}" # ` # <- Ubuntu syntax highlight fail
	for word in "${words[@]}"; do
		respond "${word}"
	done

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return 0
} # __STDLIB_API_1_std::wordsplit # }}}


###############################################################################
#
# stdlib.sh - Helper functions - Find a specified file from a selection of
#                                standardised locations
#
###############################################################################

function __STDLIB_API_1_std::findfile() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local file
	local -a app=() name=() dir=() default=() paths=() files=()

	# Usage: std::findfile [-app <name>] [-name <filename>] _
	#        [-dir <directory>] [-default <expected path>] [path ...]
	local std_PARSEARGS_parsed=0
	eval "$( std::parseargs --single --permissive --var paths -- "${@:-}" )"
	if (( std_PARSEARGS_parsed )); then
		set -- "${paths[@]:-}"
	else
		(( std_DEBUG & 2 )) && {
			warn "std::parseargs found no tagged arguments in ${FUNCNAME[0]##*_}:"
			warn "std::parseargs --single --permissive --var paths -- '${*:-}'"
		}

		eval "set -- '$( std::parseargs --strip -- "${@:-}" )'"

		app=( "${1:-}" ) ; shift
		name=( "${1:-}" ) ; shift
		dir=( "${1:-}" ) ; shift
		default=( "${1:-}" ) ; shift
	fi

	[[ -n "${name[*]:-}" || -n "${default[*]:-}" || -n "${1:-}" ]] || {
		error "${FUNCNAME[0]##*_} requires at least one filename argument"

		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	# For example, to search /etc/stdlib.colours, /etc/stdlib/colours,
	# /usr/local/etc/stdlib.colours, and a given path then invoke:
	# std::findfile -dir /etc -app stdlib -name colours
	# ... or:
	# std::findfile stdlib colours /etc

	for file in "${default[@]:-}" "${@:-}"; do
		[[ -n "${file:-}" ]] && files+=( "${file}" )
	done

	if [[ -n "${name[*]:-}" ]]; then
		if [[ -n "${dir[*]:-}" ]]; then
			if [[ -n "${app[*]:-}" ]]; then
				for file in \
					"/${dir[*]}/${app[*]}/${name[*]}" \
					"/${dir[*]}/${app[*]}.${name[*]}" \
					"/usr/local/${dir[*]}/${app[*]}/${name[*]}" \
					"/usr/local/${dir[*]}/${app[*]}.${name[*]}"
				do
					files+=( "${file//\/\///}" )
				done
			else
				for file in \
					"/${dir[*]}/${name[*]}" \
					"/usr/local/${dir[*]}/${name[*]}"
				do
					files+=( "${file//\/\///}" )
				done
			fi
		fi
		if [[ -n "${app[*]:-}" ]]; then
			for file in \
				"/${HOME:-/root}/${app[*]}/${name[*]}" \
				"/${HOME:-/root}/${app[*]}.${name[*]}" \
				"/${HOME:-/root}/.${app[*]}/${name[*]}" \
				"/${HOME:-/root}/.${app[*]}.${name[*]}"
			do
				files+=( "${file//\/\///}" )
			done
			if [[ -n "${std_LIBPATH:-}" ]]; then
				for file in \
					"/${std_LIBPATH}/${app[*]}/${name[*]}" \
					"/${std_LIBPATH}/${app[*]}.${name[*]}" \
					"/${std_LIBPATH}/.${app[*]}/${name[*]}" \
					"/${std_LIBPATH}/.${app[*]}.${name[*]}"
				do
					files+=( "${file//\/\///}" )
				done
			fi
		else
			for file in \
				"/${HOME:-/root}/${name[*]}" \
				"/${HOME:-/root}/.${name[*]}"
			do
				files+=( "${file//\/\///}" )
			done
		fi
	fi
	for file in "${files[@]}"; do
		(( std_DEBUG & 2 )) && debug "${FUNCNAME[0]##*_} checking for file '${file}' ..."

		if [[ -e "${file}" ]]; then
			(( std_DEBUG & 2 )) && debug "${FUNCNAME[0]##*_} selecting file '${file}'"
			respond "${file}"

			std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

			(( std_x_state )) && set -o xtrace

			return 0
		fi
	done

	std_ERRNO=$( errsymbol ENOTFOUND )

	(( std_x_state )) && set -o xtrace

	return 1
} # __STDLIB_API_1_std::findfile # }}}


###############################################################################
#
# stdlib.sh - Helper functions - Process sections of Windows-style .ini files
#
###############################################################################

function __STDLIB_API_1_std::getfilesection() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local file="${1:-}" ; shift
	local section="${1:-}" ; shift
	local script

	[[ -n "${file:-}" ]] || {
		std_ERRNO=$( errsymbol EARGS )

		(( std_x_state )) && set -o xtrace

		return 1
	}
	[[ -s "${file}" || -p "${file}" ]] || {
		std_ERRNO=$( errsymbol ENOTFOUND )

		(( std_x_state )) && set -o xtrace

		return 1
	}
	[[ -n "${section:-}" ]] || {
		std_ERRNO=$( errsymbol EENV )

		(( std_x_state )) && set -o xtrace

		return 1
	}

	if [[ "${section}" =~ ^\[.*\]$ ]]; then
		section="${section#[}"
		section="${section%[}"
	fi
	section="$( printf '%q' "${section}" )"

	# By printing the line before setting 'output' to 1, we prevent the
	# section header itself from being returned.
	__STDLIB_API_1_std::define script <<-EOF
		BEGIN				{ output = 0 }
		/^\s*\[.*\]\s*$/		{ output = 0 }
		( 1 == output )			{ print \$0 }
		/^\s*\[${section}\]\s*$/	{ output = 1 }
	EOF

	respond "$( awk -- "${script:-}" "${file}" )"

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	(( std_x_state )) && set -o xtrace

	return ${?}
} # __STDLIB_API_1_std::getfilesection # }}}


###############################################################################
#
# stdlib.sh - Helper functions - Map HTTP return-codes to shell return codes
#
###############################################################################

function  __STDLIB_API_1_std::http::squash() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local -i code=${1:-} ; shift
	local -i result=0

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	debug "${FUNCNAME[0]##*_} received HTTP code '${code:-}'"

	if (( ( code > 99 && code < 400 ) || ( code > 499 && code < 600 ) )); then
		(( code > 102 && code < 200 )) && warn "Attempting to squash non-RFC2616 Status Code '${code}'"
		(( code > 206 && code < 300 )) && warn "Attempting to squash non-RFC2616 Status Code '${code}'"
		(( code > 307 && code < 300 )) && warn "Attempting to squash non-RFC2616 Status Code '${code}'"
		(( code > 417 && code < 300 )) && warn "Attempting to squash non-RFC2616 Status Code '${code}'"
		(( code > 505 && code < 600 )) && warn "Attempting to squash non-RFC2616 Status Code '${code}'"

		(( code == 226 )) && code=103 # ... mapped to 13

		(( result = ( ( code / 100 ) * 10 ) + ( code - ( code / 100 ) * 100 ) ))
	elif (( code > 399 && code < 500 )); then
		(( result = ( code - 400 ) + 150 ))
	else
		error "Cannot squash non-RFC2616 Status Code '${code}'"

		std_ERRNO=$( errsymbol EARGS )
	fi

	debug "${FUNCNAME[0]##*_} returned shell code ${result}"

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return ${result}
} # __STDLIB_API_1_std::http::squash # }}}

function __STDLIB_API_1_std::http::expand() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local -i code=${1:-} ; shift
	local -i result=0
	local -i rc=0

	debug "${FUNCNAME[0]##*_} received shell code ${code:-}"

	if (( 13 == code )); then
		result=226
		rc=0
	elif (( code > 59 && code < 150 )); then
		(( result = 500 + ( code - 50 ) ))
		rc=0
	elif (( code > 149 )); then
		(( result = ( code - 150 ) + 400 ))
		rc=0
	elif (( code > 9 && code < 250 )); then
		(( result = ( ( code / 10 ) * 100 ) + ( code - ( ( code / 10 ) * 10 ) ) ))
		rc=0
	else
		rc=1
	fi

	(( result < 100 )) && { warn "Attempting to expand invalid shell code '${code}'"; result=0; rc=1; }
	(( result > 102 && result < 200 )) && warn "Attempting to expand non-RFC2616 shell code '${code}'"
	(( result > 206 && result < 300 )) && warn "Attempting to expand non-RFC2616 shell code '${code}'"
	(( result > 307 && result < 300 )) && warn "Attempting to expand non-RFC2616 shell code '${code}'"
	(( result > 417 && result < 300 )) && warn "Attempting to expand non-RFC2616 shell code '${code}'"
	(( result > 505 && result < 600 )) && warn "Attempting to expand non-RFC2616 shell code '${code}'"
	(( result > 599 )) && { warn "Attempting to expand invalid shell code '${code}'"; result=0; rc=1; }

	debug "${FUNCNAME[0]##*_} returned HTTP code '${result}': ${rc}"

	if (( rc )); then
		std_ERRNO=$( errsymbol EARGS )
	else
		std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
		respond ${result}
	fi

	(( std_x_state )) && set -o xtrace

	# Don't stomp on std_ERRNO
	return ${rc}
} # __STDLIB_API_1_std::http::expand # }}}


###############################################################################
#
# stdlib.sh - Helper functions - Allow for parameterised arguments
#
###############################################################################

function __STDLIB_API_1_std::parseargs() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local std_PARSEARGS_current="" std_PARSEARGS_arg=""
	local -i std_PARSEARGS_onevalue=0 std_PARSEARGS_unrecok=0 std_PARSEARGS_rc=1

	local std_PARSEARGS_unassigned_var='std_PARSEARGS_unassigned'
	local std_PARSEARGS_unassigned_value='__DEFINED__'

	local std_PARSEARGS_parsed=1

	std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

	if [[ "${1:-}" =~ ^(--)?strip$ ]]; then
		for std_PARSEARGS_arg in "${@:-}"; do
			(( std_PARSEARGS_rc )) || [[ "${std_PARSEARGS_arg:-}" =~ ^- ]] || respond "${std_PARSEARGS_arg:-}"
			[[ "${std_PARSEARGS_arg:-}" == '--' ]] && std_PARSEARGS_rc=0
		done

		(( std_x_state )) && set -o xtrace

		return 0
	fi

	# It would sometimes be incredibly useful to be able to pass unordered
	# or optional parameters to a shell function, without the overhead of
	# having to run getopt and parse the output for every invocation.
	#
	# The aim here is to provide a function which can be called by 'eval'
	# in order to expand command-line arguments into variable declarations.
	#
	# For example:
	#
	#   function myfunc() {
	#     local std_PARSEARGS_parsed item1 item2 item3
	#     eval "$( std::parseargs "${@:-}" )"
	#     (( std_PARSEARGS_parsed )) || {
	#       eval "set -- '$( std::parseargs --strip -- "${@:-}" )'"
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
	# variable with a value, or one otherwise.
	#
	# Any values without an obvious associated variable name are saved as
	# "std_PARSEARGS_unassigned"
	#
	# Any variable name which is specified but receives no values will be
	# given the special placeholder value "__DEFINED__".
	#
	# Internal options:
	#   --single     - Only store the value following a variable to that
	#                  variable, rather than storing everything until the
	#                  next variable name; further arguments are populated
	#                  into the variable indicated by --var, if specified
	#   --permissive - Don't return an error if no values are recognised
	#   --var <name> - Specify the variable name for unrecognised values
	#
	# If any number of Internal options are specified they MUST be followed
	# by a double-hyphen!
	#

	local -a std_PARSEARGS_results=()

	if grep -qw -- '--' <<<"${*:-}"; then # ` # <- Ubuntu syntax highlight fail
		while [[ -n "${1:-}" ]]; do
			std_PARSEARGS_current="${1}" ; shift
			case "${std_PARSEARGS_current}" in
				--onevalue|--single)
					std_PARSEARGS_onevalue=1
					;;
				--unrecok|--permissive)
					std_PARSEARGS_unrecok=1
					;;
				--unrec|--unknown|--variable|--var)
					if [[ -n "${1:-}" && "${1}" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
						if ! [[ "${1}" =~ ^std_(PARSEARGS_.+|ERRNO)$ ]]; then
							std_PARSEARGS_unassigned_var="${1}" ; shift
						else
							(( std_DEBUG )) && error "${FUNCNAME[0]##*_}: Specified name '${1}' is a reserved variable-name"
							std_PARSEARGS_parsed=0
							respond "std_PARSEARGS_parsed=${std_PARSEARGS_parsed:-0}"

							std_ERRNO=$( errsymbol EARGS )

							(( std_x_state )) && set -o xtrace

							return 1
						fi
					else
						(( std_DEBUG )) && error "${FUNCNAME[0]##*_}: Specified name '${1:-}' is not a valid variable-name"
						std_PARSEARGS_parsed=0
						respond "std_PARSEARGS_parsed=${std_PARSEARGS_parsed:-0}"

						std_ERRNO=$( errsymbol EARGS )

						(( std_x_state )) && set -o xtrace

						return 1
					fi
					;;
				--)
					break
					;;
				*)
					(( std_DEBUG )) && error "${FUNCNAME[0]##*_}: Unknown option '${std_PARSEARGS_current}'"
					std_PARSEARGS_parsed=0
					respond "std_PARSEARGS_parsed=${std_PARSEARGS_parsed:-0}"

					std_ERRNO=$( errsymbol EARGS )

					(( std_x_state )) && set -o xtrace

					return 1
					;;
			esac
		done
	fi
	eval "local -a ${std_PARSEARGS_unassigned_var:-std_PARSEARGS_unassigned}=()"
	std_PARSEARGS_arg="${std_PARSEARGS_unassigned_var}"

	set -- "${@:-}" '-std_PARSEARGS_EOF'
	while [[ -n "${1:-}" ]]; do
		std_PARSEARGS_current="${1}" ; shift

		(( 0 == ${#std_PARSEARGS_current} )) && continue

		if [[ "${std_PARSEARGS_current:0:1}" == '-' ]]; then
			if ! [[ "${std_PARSEARGS_arg}" == "${std_PARSEARGS_unassigned_var}" ]]; then
				if [[ -z "${!std_PARSEARGS_arg[*]:-}" ]]; then
					eval "${std_PARSEARGS_arg}+=( '${std_PARSEARGS_unassigned_value}' )"
					if ! grep -Fqm 1 -- " ${std_PARSEARGS_arg} " <<<" ${std_PARSEARGS_results[*]:-} "; then # ` # <- Ubuntu syntax highlight fail
						std_PARSEARGS_results+=( "${std_PARSEARGS_arg}" )
					fi
					std_PARSEARGS_rc=0
				fi
			fi

			std_PARSEARGS_arg="${std_PARSEARGS_current:1}"

			[[ "${std_PARSEARGS_arg}" == 'std_PARSEARGS_EOF' ]] && break

			# Not necessarily IEEE 1003.1-2001, but according to
			# bash source...
			if ! [[ "${std_PARSEARGS_arg:-}" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
				(( std_DEBUG )) && error "${FUNCNAME[0]##*_}: Provided name '${std_PARSEARGS_arg:-}' is not a valid variable-name"
				std_PARSEARGS_parsed=0
				respond "std_PARSEARGS_parsed=${std_PARSEARGS_parsed:-0}"

				std_ERRNO=$( errsymbol EARGS )

				(( std_x_state )) && set -o xtrace

				return 1
			elif [[ "${std_PARSEARGS_arg}" =~ ^std_(PARSEARGS_.+|ERRNO)$ ]]; then
				(( std_DEBUG )) && error "${FUNCNAME[0]##*_}: Provided name '${std_PARSEARGS_arg}' is a reserved variable-name"
				std_PARSEARGS_parsed=0
				respond "std_PARSEARGS_parsed=${std_PARSEARGS_parsed:-0}"

				std_ERRNO=$( errsymbol EARGS )

				(( std_x_state )) && set -o xtrace

				return 1
			else
				declare -p "${std_PARSEARGS_arg}" >/dev/null 2>&1 || declare -a "${std_PARSEARGS_arg}"
				if ! grep -Fqm 1 -- " ${std_PARSEARGS_arg} " <<<" ${std_PARSEARGS_results[*]:-} "; then # ` # <- Ubuntu syntax highlight fail
					std_PARSEARGS_results+=( "${std_PARSEARGS_arg}" )
				fi
			fi
		else
			if [[ -z "${std_PARSEARGS_arg:-}" ]]; then
				(( std_DEBUG & 2 )) && warn "${FUNCNAME[0]##*_}: Dropping argument '${std_PARSEARGS_current}'"
				continue
			fi

			eval "${std_PARSEARGS_arg}+=( '${std_PARSEARGS_current}' )"
			if ! grep -Fqm 1 -- " ${std_PARSEARGS_arg} " <<<" ${std_PARSEARGS_results[*]:-} "; then # ` # <- Ubuntu syntax highlight fail
				std_PARSEARGS_results+=( "${std_PARSEARGS_arg}" )
			fi
			if (( std_PARSEARGS_rc )); then
				if (( std_PARSEARGS_unrecok )) || [[ "${std_PARSEARGS_arg}" != "${std_PARSEARGS_unassigned_var}" ]]; then
					std_PARSEARGS_rc=0
				fi
			fi
			(( std_PARSEARGS_onevalue )) && std_PARSEARGS_arg="${std_PARSEARGS_unassigned_var}"
		fi
	done

	if ! (( std_PARSEARGS_rc )); then
		for std_PARSEARGS_arg in "${std_PARSEARGS_results[@]:-}"; do
			if [[ -n "${std_PARSEARGS_arg:-}" ]]; then
				if declare -p "${std_PARSEARGS_arg}" >/dev/null 2>&1; then
					respond "$( declare -p "${std_PARSEARGS_arg}" )"
				else
					(( std_DEBUG & 2 )) && warn "${FUNCNAME[0]##*_}: Variable '${std_PARSEARGS_arg}' exists but is empty"
					std_PARSEARGS_rc=1
				fi
			else
				(( std_DEBUG & 2 )) && warn "${FUNCNAME[0]##*_}: Unbound variable '${std_PARSEARGS_arg}'"
				std_PARSEARGS_rc=1
			fi
		done
	fi

	std_PARSEARGS_parsed=$(( !( std_PARSEARGS_rc ) ))
	respond "std_PARSEARGS_parsed=${std_PARSEARGS_parsed:-0}"

	(( std_PARSEARGS_rc )) && std_ERRNO=$( errsymbol EARGS )

	(( std_x_state )) && set -o xtrace

	return ${std_PARSEARGS_rc}
} # __STDLIB_API_1_std::parseargs # }}}


###############################################################################
#
# stdlib.sh - Helper functions - Export default variables, à la `configure`
#
###############################################################################

function __STDLIB_API_1_std::configure() { # {{{
	local -i std_x_state=0
	! (( std_DEBUG & 2 )) && [[ "${-/x}" != "${-}" ]] && set +o xtrace && std_x_state=1

	local -a prefix=() exec_prefix=() bindir=() sbindir=() libexecdir=() sysconfdir=()
	local -a sharedstatedir=() localstatedir=() runstatedir=() libdir=() includedir=()
	local -a oldincludedir=() datarootdir=() datadir=() infodir=() localedir=() mandir=() docdir=()
	local -a htmldir=()

	# Built-in functions should avoid depending on parseargs(), but in this
	# case the sheer number of options makes this the only sensible
	# approach... and also a great real-world example of how to make use of
	# the function above!

	local std_PARSEARGS_parsed=0
	eval "$( std::parseargs "${@:-}" )"
	(( std_PARSEARGS_parsed )) || {
		(( std_DEBUG & 2 )) && {
			warn "std::parseargs found no tagged arguments in ${FUNCNAME[0]##*_}:"
			warn "std::parseargs '${*:-}'"
		}

		eval "set -- '$( std::parseargs --strip -- "${@:-}" )'"
		prefix=( "${1:-}" )
		exec_prefix=( "${2:-}" )
		bindir=( "${3:-}" )
		sbindir=( "${4:-}" )
		libexecdir=( "${5:-}" )
		sysconfdir=( "${6:-}" )
		sharedstatedir=( "${7:-}" )
		localstatedir=( "${8:-}" )
		runstatedir=( "${9:-}" )
		libdir=( "${10:-}" )
		includedir=( "${11:-}" )
		oldincludedir=( "${12:-}" )
		datarootdir=( "${13:-}" )
		datadir=( "${14:-}" )
		infodir=( "${15:-}" )
		localedir=( "${16:-}" )
		mandir=( "${17:-}" )
		docdir=( "${18:-}" )
		htmldir=( "${19:-}" )
	}

	if [[ -n "${prefix[*]:-}" ]]; then
		export PREFIX="${prefix[0]%/}"
	else
		export PREFIX='/usr/local'
	fi
	if [[ -n "${exec_prefix[*]:-}" ]]; then
		export EXEC_PREFIX="${exec_prefix[0]%/}"
	else
		export EXEC_PREFIX="${PREFIX}"
	fi

	export BINDIR="${bindir[0]:-${EXEC_PREFIX}/bin}"
	export SBINDIR="${sbindir[0]:-${EXEC_PREFIX}/sbin}"
	export LIBEXECDIR="${libexecdir[0]:-${EXEC_PREFIX}/libexec}"
	export SYSCONFDIR="${sysconfdir[0]:-${PREFIX}/etc}"
	export SHAREDSTATEDIR="${sharedstatedir[0]:-${PREFIX}/com}"
	export LOCALSTATEDIR="${localstatedir[0]:-${PREFIX}/var}"
	export RUNSTATEDIR="${runstatedir[0]:-${LOCALSTATEDIR}/run}"
	export LIBDIR="${libdir[0]:-${EXEC_PREFIX}/lib}"
	export INCLUDEDIR="${includedir[0]:-${PREFIX}/include}"
	export OLDINCLUDEDIR="${oldincludedir[0]:-/usr/include}"
	export DATAROOTDIR="${datarootdir[0]:-${PREFIX}/share}"
	export DATADIR="${datadir[0]:-${DATAROOTDIR}}"
	export INFODIR="${infodir[0]:-${DATAROOTDIR}/info}"
	export LOCALEDIR="${localedir[0]:-${DATAROOTDIR}/locale}"
	export MANDIR="${mandir[0]:-${DATAROOTDIR}/man}"
	export DOCDIR="${docdir[0]:-${DATAROOTDIR}/doc}"
	export HTMLDIR="${htmldir[0]:-${DOCDIR}}"

	if [[ -d "${PREFIX:-}/" && -d "${EXEC_PREFIX:-}/" ]]; then
		std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'

		(( std_x_state )) && set -o xtrace

		return 0
	fi

	std_ERRNO=$( errsymbol ENOTFOUND )

	(( std_x_state )) && set -o xtrace

	return 1
} # __STDLIB_API_1_std::configure() # }}}


###############################################################################
#
# stdlib.sh - Code samples - Sample functions
#
########################################################################### {{{

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
#		[[ -n "${*:-}" ]] && echo -e "${*}"
#	fi
#} # write

# Sample function to write a lock-file
#function lock() {
#	local lockfile="${1:-/var/lock/${NAME}.lock}"
#
#	mkdir -p "$( dirname "$lockfile" )" 2>/dev/null || std::cleanup 1
#
#	if ( set -o noclobber ; echo "$$" >"$lockfile" ) 2>/dev/null; then
#		std_ERRNO=0 # instead use 'std_ERRNO=$( errsymbol ENOERROR )'
#		std::garbagecollect "${lockfile}"
#
#		# Don't stomp on std_ERRNO
#		return ${?}
#	else
#		std_ERRNO=$( errsymbol EACCESS )
#		return 1
#	fi
#
#	# Unreachable
#	std_ERRNO=$( errsymbol EERROR )
#	return 255
#} # lock

# }}}


###############################################################################
#
# stdlib.sh - Code samples - Useful functions
#
########################################################################### {{{

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
#local prefix='STDLIB' canary='local stdlib_canary=1;' stdlib_alias
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
#done | grep -FB 1 "${canary}" | grep "^${prefix}" | while read -r stdlib_alias; do
#	unalias $stdlib_alias 2>/dev/null
#done

# }}}


###############################################################################
#
# stdlib.sh - Final setup and API mapping
#
########################################################################### {{{

# This function does nothing, but we can check for its existence in order to
# determine whether stdlib.sh should be reloaded...
#
function __STDLIB_API_1_std::sentinel() { # {{{
	:
} # __STDLIB_API_1_std::sentinel # }}}

__STDLIB_oneshot_get_bash_version
unset __STDLIB_oneshot_get_bash_version

__STDLIB_oneshot_syntax_check || exit 1
unset __STDLIB_oneshot_syntax_check

__STDLIB_oneshot_errno_init
#unset __STDLIB_oneshot_errno_init

# Prior to APIv2 (where is was first used), the control-variable to speficy the
# API to provide was STDLIB_API rather than STDLIB_WANT_API - so still allow
# this to be used, just in case...
declare -i __STDLIB_LATEST_API="${std_RELEASE%%.*}"
declare -i __STDLIB_API="${STDLIB_WANT_API:-${STDLIB_API:-${__STDLIB_LATEST_API:-1}}}"
case "${__STDLIB_API}" in
	1|2)
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
declare std_LIB="${std_LIB:-stdlib.sh}"
for std_LIBPATH in \
	 ${std_LIBPATH:-} \
	'/usr/local/lib' \
	"$( dirname -- "${BASH_SOURCE:-${0:-.}}" )/../lib" \
	"$( dirname "$( type -pf "${std_LIB}" 2>/dev/null )" )" \
	'.' \
	"$( dirname -- "${BASH_SOURCE:-${0:-.}}" )" \
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
		&& [[ "${std_LIBPATH=}" != '/usr/local/lib' ]]; then
		output >&2 "WARN:   ${std_LIB} Internal: Including ${std_LIB}"
			"from non-standard path '${std_LIBPATH}'"
	fi
else
	output >&2 "FATAL:  Cannot locate ${std_LIB} library functions"
	exit 1
fi
typeset -gx std_LIBPATH std_LIB

# Red Hat/CentOS 5.x ship with a version of grep which can't parse '\s', and
# so '[[:space:]]' has to be used instead.  We can work around this as follows,
# but it does negatively impact processing speed:
declare s='\s'
echo ' ' | eval "grep -Eq '${s}'" || s='[[:space:]]'

# MacOS ships with a (non-GNU) version of sed which both lacks the '-r' option,
# but instead uses '-E'.  It still can't grok '\s' for [[:space:]], though...
# Worse, MacOS/BSD sed doesn't understand '\+', so extended mode is required.
sed='sed -r'
echo '' | ${sed} >/dev/null 2>&1 || sed='sed -E'

[[ "$( echo ' ' | ${sed} 's/\s/x/' )" == 'x' ]] || s='[[:space:]]'

# Create interface for functions of the appropriate API...
#
# N.B.: Avoid pipes to maintain scope of new definitions.
#
declare -a __STDLIB_functionlist
while read -r fapi; do

	# Export all API versions, so that explicit implmentations are still
	# available...
	#
	if grep -q '^__STDLIB_API_' <<<"${fapi}"; then # ` # <- Ubuntu syntax highlight fail

		# Ensure that function is still available...
		#
		if [[ 'function' == "$( type -t "${fapi}" 2>/dev/null )" ]]; then

			# Make functions available to child shells...
			#
			# shellcheck disable=SC2163
			export -f "${fapi}"

			declare -i api
			# shellcheck disable=SC2086
			for api in $( seq ${__STDLIB_API} -1 1 ); do
				if grep -q "^__STDLIB_API_${api}_" <<<"${fapi}"; then
					if fname="$( ${sed} 's/^__STDLIB_API_[0-9]+_//' <<<"${fapi}" )"; then
						__STDLIB_functionlist+=( "${fname}" )
						eval "function ${fname}() { ${fapi} \"\${@:-}\"; }"

						# Make functions available to child shells...
						#
						# shellcheck disable=SC2163
						export -f "${fname}"

						# Clear the variable, not the function definition...
						#
						unset fname

						# Don't create any further accessors for this name...
						#
						break
					fi
				fi
			done
			unset api
		fi
	fi

	#
	# Here's a strange thing... 'grep' in CentOS 5.8 (and likely others)
	# doesn't like '\s', so this needs to be swapped for the longer and
	# less readable '[[:space:]]' in the code below...
	#
	#  grep '^[[:space:]]*function[[:space:]]\+[a-zA-Z_]\+[a-zA-Z0-9_-]*[[:space:]]*()[[:space:]]*{\?[[:space:]]*$'
	#
	# ... or, experiments show, \W ([^[:alnum:]]) appears to be an
	# acceptable alternative (as would '[ ${std_TAB}]' also be)!
	#
	# Update: Reverted to 'grep -E' in the third line below in place of:
	#| grep '^\W*function\W\+[a-zA-Z_]\+[a-zA-Z0-9_:\-]*\W*()\W*{\?\W*$' \
	#
	# N.B.: Moved comment before the code below due to syntax-highlighter
	# breakage.
	#

done < <(
	  grep 'function' "${std_LIBPATH:-.}/${std_LIB}" \
	| sed 's/#.*$//' \
	| eval "grep -E '^${s}*function${s}+[a-zA-Z_]+[a-zA-Z0-9_:\-]*${s}*\(\)${s}*\{?${s}*$'" \
	| ${sed} "s/^${s}*function${s}+([a-zA-Z_]+[a-zA-Z0-9_:\-]*)${s}*\(\)${s}*\{?${s}*$/\1/"
)
unset fapi sed s

# We also need to export the internal (and increasingly inaccurately
# named ;) 'oneshot' functions which populated shared associative
# arrays so that they can be re-invoked by child shells whose parent
# also includes stdlib...
export -f __STDLIB_oneshot_errno_init
export -f __STDLIB_oneshot_colours_init

# Also export non-API-versioned functions...
#
# shellcheck disable=SC2034
typeset -fgx output respond

typeset -gax __STDLIB_functionlist

typeset -gix STDLIB_HAVE_STDLIB=1

# The 'std::cleanup' stub for the appropriate API should be in place by now...
#
if [[ "$( type -t 'std::cleanup' 2>/dev/null )" == 'function' ]]; then
	declare __STDLIB_SIGINT __STDLIB_SIGTERM __STDLIB_SIGQUIT __STDLIB_SIGEXIT
	__STDLIB_SIGEXIT="$( trap -p EXIT | cut -d"'" -f 2 )"
	__STDLIB_SIGQUIT="$( trap -p QUIT | cut -d"'" -f 2 )"
	__STDLIB_SIGTERM="$( trap -p TERM | cut -d"'" -f 2 )"

	if [[ "${BASH_SOURCE:-${0:-}}" =~ ${std_LIB:-stdlib.sh}$ ]]; then
		trap std::cleanup EXIT QUIT TERM
	else
		__STDLIB_SIGINT="$( trap -p INT | cut -d"'" -f 2 )"
		trap std::cleanup EXIT INT QUIT TERM
	fi
	export __STDLIB_SIGINT __STDLIB_SIGTERM __STDLIB_SIGQUIT __STDLIB_SIGEXIT
fi

__STDLIB_oneshot_colours_init
#unset __STDLIB_oneshot_colours_init

if [[ -r "${std_LIBPATH}"/memcached.sh ]]; then
	if [[ -n "${STDLIB_WANT_MEMCACHED:-}" ]] && ! (( STDLIB_HAVE_MEMCACHED )); then
		# shellcheck source=/usr/local/lib/memcached.sh disable=SC1091
		source "${std_LIBPATH}"/memcached.sh &&
			typeset -gix STDLIB_HAVE_MEMCACHED=1
	fi
fi

# }}}

fi # [[ "$( type -t 'std::sentinel' 2>&1 )" != 'function' ]] # Line 129

[[ -n "${STDLIB_REUSE_TEMPFILES:-}" ]] &&
	warn "Internal option 'STDLIB_REUSE_TEMPFILES' is set but is" \
	     'potentially unsafe'

true


###############################################################################
#
# stdlib.sh - EOF
#
###############################################################################

# vi: set filetype=sh syntax=sh commentstring=#%s foldmarker=\ {{{,\ }}} foldmethod=marker colorcolumn=80 nowrap:
