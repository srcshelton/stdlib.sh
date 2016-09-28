#!/bin/bash

# Portions Copyright 2016 Daniele Borsaro
# Portions Copyright 2013-2016 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2
#
# test.sh - Basic functionality checks for stdlib.sh
#
# TODO: Migrate to a bash unit-testing framework (github.com/pgrange/bash_unit?)
#       Expand coverage to all non-trivial fucntions
#

export STDLIB_WANT_COLOUR=1

# {{{
# stdlib.sh should be in /usr/local/lib/stdlib.sh, which can be found as
# follows by scripts located in /usr/local/{,s}bin/...
type -pf 'dirname' >/dev/null 2>&1 || function dirname() { : ; }
declare std_LIB="stdlib.sh"
for std_LIBPATH in							\
	"$( dirname -- "${BASH_SOURCE:-${0:-.}}" )"			\
	"."								\
	"$( dirname -- "$( type -pf "${std_LIB}" 2>/dev/null )" )"	\
	"$( dirname -- "${BASH_SOURCE:-${0:-.}}" )/../lib"		\
	"/usr/local/lib"						\
	 ${FPATH:+${FPATH//:/ }}					\
	 ${PATH:+${PATH//:/ }}
do
	if [[ -r "${std_LIBPATH}/${std_LIB}" ]]; then
		break
	fi
done
unset -f dirname
#
# We want the non if-then-else functionality here - the third element should be
# executed if either of the first two fail...
#
# N.B. The shellcheck 'source' option is only valid with shellcheck 0.4.0 and
#      later...
#
# shellcheck disable=SC1091,SC2015
# shellcheck source=stdlib.sh
[[ -r "${std_LIBPATH}/${std_LIB}" ]] && source "${std_LIBPATH}/${std_LIB}" || {
	echo >&2 "FATAL:  Unable to source ${std_LIB} functions"
	exit 1
}
# }}}

# Defined in stdlib.sh
# shellcheck disable=SC2154
(( std_TRACE )) && set -o xtrace

###############################################################################
#
# stdlib.sh - Code tests - Confirm correct operation of more complex functions
#
########################################################################### {{{

# N.B.: These functions are not versioned, as they aren't intended for general
#       use.  However, functions are free to interrogate the API version and
#       may still perform version-specific tests.
#
function emktemp::test() { # {{{
	local tempfile
	local -i result=0

	local func="std::emktemp"

	# Test 1 # {{{
	(
		local check="Test 1"
		local -i rc=0

		std::emktemp tempfile
		debug "${func} created file '${tempfile:-}' with no arguments"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no file-name"
			rc=1
		else
			if ! [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
				error "Temporary file '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
					error "std::cleanup failed to remove file '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 2 # {{{
	(
		local check="Test 2"
		local -i rc=0

		std::emktemp tempfile "${$}"
		debug "${func} created file '${tempfile:-}' with template '${$}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no file-name"
			rc=1
		else
			if ! [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
				error "Temporary file '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
					error "std::cleanup failed to remove file '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 3 # {{{
	(
		local check="Test 3"
		local -i rc=0

		std::emktemp -var tempfile -suffix "${$}"
		debug "${func} created file '${tempfile:-}' with suffix '${$}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no file-name"
			rc=1
		else
			if ! [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
				error "Temporary file '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
					error "std::cleanup failed to remove file '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 4 # {{{
	(
		local check="Test 4"
		local -i rc=0

		mkdir "${TMPDIR:-/tmp}"/stdlib-"${NAME}" || die "Cannot mkdir('${TMPDIR:-/tmp}/stdlib-${NAME}')"

		std::emktemp -var tempfile -tmpdir "${TMPDIR:-/tmp}/stdlib-${NAME}" -suffix "${$}"
		debug "${func} created file '${tempfile:-}' with tmpdir '${TMPDIR:-/tmp}/stdlib-${NAME}' and suffix '${$}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no file-name"
			rc=1
		else
			if ! [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
				error "Temporary file '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
					error "std::cleanup failed to remove file '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		rmdir "${TMPDIR:-/tmp}"/stdlib-"${NAME}" || die "Cannot rmdir('${TMPDIR:-/tmp}/stdlib-${NAME}')"

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 5 # {{{
	(
		local check="Test 5"
		local -i rc=0

		std::emktemp -var tempfile -suffix "${$}" -directory
		debug "${func} created directory '${tempfile:-}' with suffix '${$}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no directory-name"
			rc=1
		else
			if ! [[ -e "${tempfile}" && -d "${tempfile}" ]]; then
				error "Temporary directory '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -d "${tempfile}" ]]; then
					error "std::cleanup failed to remove directory '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 6 # {{{
	(
		local check="Test 6"
		local -i rc=0

		mkdir "${TMPDIR:-/tmp}"/stdlib-"${NAME}" || die "Cannot mkdir('${TMPDIR:-/tmp}/stdlib-${NAME}')"

		std::emktemp -var tempfile -tmpdir "${TMPDIR:-/tmp}/stdlib-${NAME}" -suffix "${$}" -directory
		debug "${func} created directory '${tempfile:-}' with tmpdir '${TMPDIR:-/tmp}/stdlib-${NAME}' and suffix '${$}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no directory-name"
			rc=1
		else
			if ! [[ -e "${tempfile}" && -d "${tempfile}" ]]; then
				error "Temporary directory '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -d "${tempfile}" ]]; then
					error "std::cleanup failed to remove directory '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		rmdir "${TMPDIR:-/tmp}"/stdlib-"${NAME}" || die "Cannot rmdir('${TMPDIR:-/tmp}/stdlib-${NAME}')"

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	if (( result )); then
		error "${FUNCNAME[0]##*_} failed test-suite"
	else
		info "${FUNCNAME[0]##*_} passed test-suite"
	fi

	# Don't stomp std_ERRNO
	return ${result}
} # emktemp::test # }}}

function http::test() { # {{{
	local -i ic=0 rc=0 code=0 result=0

	(( STDLIB_HAVE_BASH_4 )) || {
		# Defined in stdlib.sh
		# shellcheck disable=SC2154

		(( std_DEBUG )) && error "${FUNCNAME[0]##*_} requires bash-4 associative arrays"

		std_ERRNO=$( errsymbol ENOEXE )
		return 1
	}

	local -A codes
	# 1xx Informational
	codes[100]='Continue'
	codes[101]='Switching Protocols'
	# Non-RFC2616 Status Codes
	codes[102]='Processing' # RFC2518; WebDAV
	# 2xx Successful
	codes[200]='OK'
	codes[201]='Created'
	codes[202]='Accepted'
	codes[203]='Non-Authoritative Information' # Since HTTP/1.1
	codes[204]='No Content'
	codes[205]='Reset Content'
	codes[206]='Partial Content'
	# Non-RFC2616 Status Codes
	codes[207]='Multi-Status' # RFC4918; WebDAV
	codes[208]='Already Reported' # RFC5842; WebDAV
	codes[226]='IM Used' # RFC3229; WebDAV
	# 3xx Redirection
	codes[300]='Multiple Choices'
	codes[301]='Moved Permanently'
	codes[302]='Found'
	codes[303]='See Other' # Since HTTP/1.1
	codes[304]='Not Modified'
	codes[305]='Use Proxy' # Since HTTP/1.1
	codes[306]='(Switch Proxy - Unused)'
	codes[307]='Temporary Redirect'
	# Non-RFC2616 Status Codes
	codes[308]='Permanent Redirect' # RFC7238; Experimental
	# 4xx Client Error
	codes[400]='Bad Request'
	codes[401]='Unauthorized'
	codes[402]='Payment Required'
	codes[403]='Forbidden'
	codes[404]='Not Found'
	codes[405]='Method Not Allowed'
	codes[406]='Not Acceptable'
	codes[407]='Proxy Authentication Required'
	codes[408]='Request Timeout'
	codes[409]='Conflict'
	codes[410]='Gone'
	codes[411]='Length Required'
	codes[412]='Precondition Failed'
	codes[413]='Request Entity Too Large'
	codes[414]='Request-URI Too Long'
	codes[415]='Unsupported Media Type'
	codes[416]='Requested Range Not Satisfiable'
	codes[417]='Expectation Failed'
	# Non-RFC2616 Status Codes
	codes[418]="I'm a teapot" # RFC2324
	codes[419]='Authentication Timeout' # *Not* in RFC2616
	codes[420]='Method Failure/Enhance Your Calm' # Spring; Deprecated/Twitter API v1.0
	codes[421]='Expectation Failed'
	codes[422]='Unprocessable Entity' # RFC4918; WebDAV
	codes[423]='Locked' # RFC4918; WebDAV
	codes[424]='Failed Dependency' # RFC4918; WebDAV
	codes[426]='Upgrade Required'
	codes[428]='Precondition Required' # RFC6585
	codes[429]='Too Many Requests' # RFC6585
	codes[431]='Request Header Fields Too Large' # RFC6585
	codes[440]='Login Timeout' # Microsoft
	codes[444]='No Response' # nginx
	codes[449]='Retry With' # Microsoft
	codes[450]='Blocked by Windows Parental Controls' # Microsoft
	codes[451]='Unavailable For Legal Reasons/Redirect' # Draft/Microsoft
	codes[494]='Request Header Too Large' # nginx
	codes[495]='Cert Error' # nginx
	codes[496]='No Cert' # nginx
	codes[497]='HTTP to HTTPS' # nginx
	codes[498]='Token expired/invalid' # ersi
	codes[499]='Client Closed Request/Token Required' # nginx/ersi
	# 5xx Server Error
	codes[500]='Internal Server Error'
	codes[501]='Not Implemented'
	codes[502]='Bad Gateway'
	codes[503]='Service Unavailable'
	codes[504]='Gateway Timeout'
	codes[505]='HTTP Version Not Supported'
	# Non-RFC2616 Status Codes
	codes[506]='Variant Also Negotiates' # RFC2295
	codes[507]='Insufficient Storage' # RFC4918; WebDAV
	codes[508]='Loop Detected' # RFC5842; WebDAV
	codes[509]='Bandwidth Limit Exceeded' # Apache
	codes[510]='Not Extended' # RFC2774
	codes[511]='Network Authentication Required' # RFC6585
	codes[520]='Origin Error' # CloudFlare
	codes[521]='Web server is down' # CloudFlare
	codes[522]='Connection timed out' # CloudFlare
	codes[523]='Proxy Declined Request' # CloudFlare
	codes[524]='A timeout occurred' # CloudFlare
	codes[598]='Network read timeout error' # Microsoft
	codes[599]='Network connect timeout error' # Microsoft

	output "Testing HTTP-to-shell response-code mappings\n"
	output "N.B.: non-RFC2616 status codes are expected failures\n"

	std_ERRNO=0

	# 'ic' and 'code' are numeric, and therefore not subject to word-splitting
	# shellcheck disable=SC2086
	for code in $( for ic in "${!codes[@]}"; do echo ${ic}; done | sort -n ); do
		std::http::squash ${code} 2>/dev/null ; ic=${?}
		rc=$( std::http::expand ${ic} )
		if (( code == rc )); then
			info "${code} '${codes[${code}]}' -> ${ic} -> ${rc} : Okay"
		else
			warn "${code} '${codes[${code}]}' -> ${ic} -> ${rc} : FAIL"
			result=1
			std_ERRNO=$( errsymbol EERROR )
		fi
	done

	# Don't stomp std_ERRNO
	return ${result}
} # http::test # }}}

function mktemp::test() { # {{{
	local tempfile
	local -i result=0

	local func="std::mktemp"

	if [[ -e "${TMPDIR:-/tmp}"/stdlib-"${NAME}" ]]; then
		error "Cannot run test-suite if filesystem object '${TMPDIR:-/tmp}/stdlib-${NAME}' exists"
		return 1
	fi

	# Test 1 # {{{
	(
		local check="Test 1"
		local -i rc=0

		tempfile="$( std::mktemp )"
		debug "${func} created file '${tempfile:-}' with no arguments"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no file-name"
			rc=1
		else
			std::garbagecollect "${tempfile}"
			if ! [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
				error "Temporary file '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
					error "std::cleanup failed to remove file '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 2 # {{{
	(
		local check="Test 2"
		local -i rc=0

		tempfile="$( std::mktemp "stdlib-${NAME}" )"
		debug "${func} created file '${tempfile:-}' with template 'stdlib-${NAME}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no file-name"
			rc=1
		else
			std::garbagecollect "${tempfile}"
			if ! [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
				error "Temporary file '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
					error "std::cleanup failed to remove file '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 3 # {{{
	(
		local check="Test 3"
		local -i rc=0

		tempfile="$( std::mktemp -suffix "${$}" "stdlib-${NAME}" )"
		debug "${func} created file '${tempfile:-}' with suffix '${$}' and template 'stdlib-${NAME}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no file-name"
			rc=1
		else
			std::garbagecollect "${tempfile}"
			if ! [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
				error "Temporary file '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
					error "std::cleanup failed to remove file '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 4 # {{{
	(
		local check="Test 4"
		local -i rc=0

		mkdir "${TMPDIR:-/tmp}"/stdlib-"${NAME}" || die "Cannot mkdir('${TMPDIR:-/tmp}/stdlib-${NAME}')"

		tempfile="$( std::mktemp -tmpdir "${TMPDIR:-/tmp}/stdlib-${NAME}" -suffix "${$}" "stdlib-${NAME}" )"
		debug "${func} created file '${tempfile:-}' with tmpdir ${TMPDIR:-/tmp}/stdlib-${NAME}', suffix '${$}' and template 'stdlib-${NAME}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no file-name"
			rc=1
		else
			std::garbagecollect "${tempfile}"
			if ! [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
				error "Temporary file '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -f "${tempfile}" ]]; then
					error "std::cleanup failed to remove file '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		rmdir "${TMPDIR:-/tmp}"/stdlib-"${NAME}" || die "Cannot rmdir('${TMPDIR:-/tmp}/stdlib-${NAME}')"

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 5 # {{{
	(
		local check="Test 5"
		local -i rc=0

		#local -i std_debug="${std_DEBUG}"
		#std_DEBUG=2
		tempfile="$( std::mktemp -directory -suffix "${$}" "stdlib-${NAME}" )"
		#std_DEBUG="${std_debug}"
		debug "${func} created directory '${tempfile:-}' with suffix '${$}' and template 'stdlib-${NAME}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no directory-name"
			rc=1
		else
			std::garbagecollect "${tempfile}"
			if ! [[ -e "${tempfile}" && -d "${tempfile}" ]]; then
				error "Temporary directory '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -d "${tempfile}" ]]; then
					error "std::cleanup failed to remove directory '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 6 # {{{
	(
		local check="Test 6"
		local -i rc=0

		mkdir "${TMPDIR:-/tmp}"/stdlib-"${NAME}" || die "Cannot mkdir('${TMPDIR:-/tmp}/stdlib-${NAME}')"

		tempfile="$( std::mktemp -directory -tmpdir "${TMPDIR:-/tmp}/stdlib-${NAME}" -suffix "${$}" "stdlib-${NAME}" )"
		debug "${func} created directory '${tempfile:-}' with tmpdir '${TMPDIR:-/tmp}/stdlib-${NAME}', suffix '${$}' and template 'stdlib-${NAME}'"
		if ! [[ -n "${tempfile:-}" ]]; then
			error "${func} returned no directory-name"
			rc=1
		else
			std::garbagecollect "${tempfile}"
			if ! [[ -e "${tempfile}" && -d "${tempfile}" ]]; then
				error "Temporary directory '${tempfile}' does not exst"
				rc=1
			else
				(
					#export std_DEBUG=2
					std::cleanup 0
				)
				rc+=${?}

				if [[ -e "${tempfile}" && -d "${tempfile}" ]]; then
					error "std::cleanup failed to remove directory '${tempfile}'"
					(( rc++ ))
				else
					info "${func} ${check}: okay"
				fi
			fi
		fi

		rmdir "${TMPDIR:-/tmp}"/stdlib-"${NAME}" || die "Cannot rmdir('${TMPDIR:-/tmp}/stdlib-${NAME}')"

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	if (( result )); then
		error "${FUNCNAME[0]##*_} failed test-suite"
	else
		info "${FUNCNAME[0]##*_} passed test-suite"
	fi

	# Don't stomp std_ERRNO
	return ${result}
} # mktemp::test # }}}

function output::test() { # {{{
	local -i debug=${std_DEBUG:-0}

	output "Colourisation test:\n"

	std::colour "Message"
	std::colour "Multi-word message"
	output
	std::colour "WARN: Warning"
	std::colour "warning message"
	std::colour "info information"
	std::colour "information: info"
	std::colour "NOTICE: Notice"
	std::colour "note: Notice"
	std::colour "debug debug"
	std::colour "warn warn"
	std::colour "warning warning"
	std::colour "error error"
	output
	std::colour Red "Text in red specified inline"
	output
	std::colour -colour black "Black"
	std::colour -colour red "Red"
	std::colour -colour green "Green"
	std::colour -colour yellow "Yellow"
	std::colour -colour blue "Blue"
	std::colour -colour magenta "Magenta"
	std::colour -colour cyan "Cyan"
	std::colour -colour white "White"
	std::colour -colour $(( ( 1 << 16 ) + 0 )) "Bright Black"
	std::colour -colour $(( ( 1 << 16 ) + 1 )) "Bright Red"
	std::colour -colour $(( ( 1 << 16 ) + 2 )) "Bright Green"
	std::colour -colour $(( ( 1 << 16 ) + 3 )) "Bright Yellow"
	std::colour -colour $(( ( 1 << 16 ) + 4 )) "Bright Blue"
	std::colour -colour $(( ( 1 << 16 ) + 5 )) "Bright Magenta"
	std::colour -colour $(( ( 1 << 16 ) + 6 )) "Bright Cyan"
	std::colour -colour $(( ( 1 << 16 ) + 7 )) "Bright White"
	std::colour -colour $(( ( 4 << 16 ) + ( 3 << 8 ) + 4 )) "Underlined blue on yellow"
	output
	std::colour -type debug "This is debug"
	std::colour -type error "This is error"
	std::colour -type exec "This is exec"
	std::colour -type fail "This is fail"
	std::colour -type fatal "This is fatal"
	std::colour -type info "This is info"
	std::colour -type note "This is note"
	std::colour -type notice "This is notice"
	std::colour -type okay "This is okay"
	std::colour -type ok "This is ok"
	std::colour -type warn "This is warn"
	output
	std::colour -type fatal -colour yellow "!!! Yellow text following red fatal prefix"
	std::colour -type okay -colour magenta "!!! Magenta text following green ok prefix"
	output
	std::colour -colour $(( ( 1 << 16 ) + 2 )) "Bright green"
	std::colour -colour $(( 2 )) "Dim green"
	output
	info "Info"
	notice "Notice"
	note "Note"
	std_DEBUG=0 debug "This should not be displayed..."
	std_DEBUG=1 debug "Debug"
	std_DEBUG=${debug}
	warn "Warning"
	error "Error"
	( die "Die" )

	output "\nSpacing test:"
	output "         11111111112"
	output "12345678901234567890"
	std::colour -colour white "1                   "
	std::colour -colour white "    5               "
	std::colour -colour white "1   5               "
	std::colour -colour white "        9           "
	std::colour -colour white "1       9           "
	std::colour -colour white "    5   9           "
	std::colour -colour white "1   5   9           "
	std::colour -colour white "1   5   9   *       "
	std::colour -colour white "1   5   9   *   +   "
	echo " $( std::colour -colour white "2 4 6 8 - * + ! @ #" )x"
	echo -n ' ' ; echo -n "$( std::colour -colour white "2 4 6 8 - * + ! @ #" )" ; echo 'x'
	echo -n "$( std::colour -colour white "1 3 5 7 9 # @ ! + *" )" ; echo ' x'

	output "\nColourisation test complete"

	# Defined in stdlib.sh
	# shellcheck disable=SC2034
	std_ERRNO=0
	return 0
} # output::test # }}}

function parseargs::test() { # {{{
	local response expected item1 item2 item3 unknown
	local -i std_PARSEARGS_parsed=0 result=0
	local -a args

	# Clear any arguments we were called with...
	while [[ -n "${1:-}" || -n "${*:-}" ]]; do
		shift
	done

	local func="std::parseargs"

	# Test 1 # {{{
	(
		local check="Test 1"
		local -i rc=0 testresult=0

		args=( -item1 a -item2 b -item3 c )
		(( std_DEBUG )) && info "Stripping arguments from '${args[*]}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --strip -- "${args[@]}" )"
		eval "set -- '$( std::parseargs --strip -- "${args[@]}" )'"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${*:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "item1 is '${item1:-}', '${item1[*]:-}'"
			echo "item2 is '${item2:-}', '${item2[*]:-}'"
			echo "item3 is '${item3:-}', '${item3[*]:-}'"
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
		fi
		# Doesn't apply when stripping arguments
		#(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x



a
b
c
x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	#output "\n"
	# Test 2 # {{{
	(
		local check="Test 2"
		local -i rc=0 testresult=0

		args=( -item1 a b -item2 c d -item3 e )
		(( std_DEBUG )) && info "Stripping arguments from '${args[*]}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --strip -- "${args[@]}" )"
		eval "set -- '$( std::parseargs --strip -- "${args[@]}" )'"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${*:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "item1 is '${item1:-}', '${item1[*]:-}'"
			echo "item2 is '${item2:-}', '${item2[*]:-}'"
			echo "item3 is '${item3:-}', '${item3[*]:-}'"
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
		fi
		# Doesn't apply when stripping arguments
		#(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x



a
b
c
d
e
x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	#output "\n"
	# Test 3 # {{{
	(
		local check="Test 3"
		local -i rc=0 testresult=0

		args=( -item1 a -item2 b -item3 c )
		(( std_DEBUG )) && info "Argument-parsing '${args[*]}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --single --permissive --var unknown -- "${args[@]}" )"
		eval "$( std::parseargs --single --permissive --var unknown -- "${args[@]}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "item1 is '${item1:-}', '${item1[*]:-}'"
			echo "item2 is '${item2:-}', '${item2[*]:-}'"
			echo "item3 is '${item3:-}', '${item3[*]:-}'"
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x
a
b
c

x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	#output "\n"
	# Test 4 # {{{
	(
		local check="Test 4"
		local -i rc=0 testresult=0

		args=( -item1 a b -item2 c d -item3 e )
		(( std_DEBUG )) && info "Argument-parsing '${args[*]}' with --single ..."

		(( std_DEBUG )) && debug "$( std::parseargs --single --permissive --var unknown -- "${args[@]}" )"
		eval "$( std::parseargs --single --permissive --var unknown -- "${args[@]}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "item1 is '${item1:-}', '${item1[*]:-}'"
			echo "item2 is '${item2:-}', '${item2[*]:-}'"
			echo "item3 is '${item3:-}', '${item3[*]:-}'"
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x
a
c
e
b d
x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	#output "\n"
	# Test 5 # {{{
	(
		local check="Test 5"
		local -i rc=0 testresult=0

		args=( -item1 a b -item2 c d -item3 e )
		(( std_DEBUG )) && info "Argument-parsing '${args[*]}' without --single ..."

		(( std_DEBUG )) && debug "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "item1 is '${item1:-}', '${item1[*]:-}'"
			echo "item2 is '${item2:-}', '${item2[*]:-}'"
			echo "item3 is '${item3:-}', '${item3[*]:-}'"
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x
a b
c d
e

x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))

	# }}}

	#output "\n"
	# Test 6 # {{{
	(
		local check="Test 6"
		local -i rc=0 testresult=0

		args=( -item1 "a b" c -item2 d "e f" -item3 "g h" "i j" )
		(( std_DEBUG )) && info "Argument-parsing '${args[*]}' without --single ..."

		(( std_DEBUG )) && debug "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		response="$(
			echo "x"
			echo "${item1[0]:-}"
			echo "${item1[1]:-}"
			echo "${item2[0]:-}"
			echo "${item2[1]:-}"
			echo "${item3[0]:-}"
			echo "${item3[1]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "item1 is '${item1:-}', '${item1[*]:-}'"
			echo "item2 is '${item2:-}', '${item2[*]:-}'"
			echo "item3 is '${item3:-}', '${item3[*]:-}'"
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x
a b
c
d
e f
g h
i j

x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	#output "\n"
	# Test 7 # {{{
	(
		local check="Test 7"
		local -i rc=0 testresult=0

		args=( a )
		(( std_DEBUG )) && info "Argument-parsing '${args[*]}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x



a
x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))

	# }}}

	#output "\n"
	std::colour -type warn -colour red "WARN:   Test 8 expected failure"
	# Test 8 # {{{
	(
		local check="Test 8"
		local -i rc=0 testresult=0

		args=()
		(( std_DEBUG )) && info "Argument-parsing '${args[*]:-}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --permissive --var unknown -- "${args[@]:-}" )"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]:-}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			info "${func} ${check} failed: ${rc}"
			#testresult=1
		#else
			std::define expected <<'EOF'
x




x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				#info "${func} ${check}: okay"
				:
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				#testresult=1
			fi
		# Expected failure
		else
			testresult=1
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}
	#output "\n"
	std::colour -type warn -colour red "WARN:   Test 9 expected failure (without --permissive):"
	# Test 9 # {{{
	(
		local check="Test 9"
		local -i rc=0 testresult=0

		args=( a )
		(( std_DEBUG )) && info "Argument-parsing '${args[*]}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --var unknown -- "${args[@]}" )"
		eval "$( std::parseargs --var unknown -- "${args[@]}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			info "${func} ${check} failed: ${rc}"
			#testresult=1
		#else
			std::define expected <<'EOF'
x




x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				#info "${func} ${check}: okay"
				:
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				#testresult=1
			fi
		# Expected failure
		else
			testresult=1
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	#output "\n"
	std::colour -type warn -colour red "WARN:   Test 10 expected failure (without --permissive):"
	# Test 10 # {{{
	(
		local check="Test 10"
		local -i rc=0 testresult=0

		args=()
		(( std_DEBUG )) && info "Argument-parsing '${args[*]:-}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --var unknown -- "${args[@]:-}" )"
		eval "$( std::parseargs --var unknown -- "${args[@]:-}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			info "${func} ${check} failed: ${rc}"
			#testresult=1
		#else
			std::define expected <<'EOF'
x




x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				#info "${func} ${check}: okay"
				:
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				#testresult=1
			fi
		# Expected failure
		else
			testresult=1
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	#output "\n"
	# Test 11 # {{{
	(
		local check="Test 11"
		local -i rc=0 testresult=0

		args=( -item1 )
		(( std_DEBUG )) && info "Argument-parsing '${args[*]:-}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --permissive --var unknown -- "${args[@]:-}" )"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]:-}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "item1 is '${item1:-}', '${item1[*]:-}'"
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x
__DEFINED__



x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	#output "\n"
	# Test 12 # {{{
	(
		local check="Test 12"
		local -i rc=0 testresult=0

		args=( -item1 -item2 )
		(( std_DEBUG )) && info "Argument-parsing '${args[*]:-}' ..."

		(( std_DEBUG )) && debug "$( std::parseargs --permissive --var unknown -- "${args[@]:-}" )"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]:-}" )"
		response="$(
			echo "x"
			echo "${item1[*]:-}"
			echo "${item2[*]:-}"
			echo "${item3[*]:-}"
			echo "${unknown[*]:-}"
			echo "x"
		)"
		rc=${?}
		if (( std_DEBUG )); then
			echo "item1 is '${item1:-}', '${item1[*]:-}'"
			echo "item2 is '${item2:-}', '${item2[*]:-}'"
			echo "unknown is '${unknown:-}', '${unknown[*]:-}'"
		fi

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				(( std_DEBUG )) && output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
		(( rc )) || rc=$(( ! std_PARSEARGS_parsed ))

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
x
__DEFINED__
__DEFINED__


x
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "$( grep -v '^x$' <<<"${expected}" )"
				info "Received:"
				output "$( grep -v '^x$' <<<"${response}" )"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	if (( result )); then
		error "${FUNCNAME[0]##*_} failed test-suite"
	else
		info "${FUNCNAME[0]##*_} passed test-suite"
	fi

	# Don't stomp std_ERRNO
	return ${result}
} # parseargs::test # }}}

function push::test() { # {{{
	local -i result=0
	# Test-cases from https://github.com/vaeth/push/blob/71794c14a709d4ef2816d76db89c2b7f41a0b650/README

	local response expected
	local -a fargs=( "${@:-}" )

	local func="std::push"

	# Example 1 # {{{
	(
		local check="Example 1"
		local -i rc=0 testresult=0

		local foo

		# shellcheck disable=SC1003
		response="$(
			set -e
			std::push -c foo 'data with special symbols like ()"\' "'another arg'"
			std::push foo further args
			eval "printf '%s\\n' ${foo}"
		)" 2>/dev/null
		rc=${?}

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
data with special symbols like ()"\
'another arg'
further
args
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "${expected}"
				info "Received:"
				output "${response}"
				testresult=1
			fi
		fi

		unset foo

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	# Example 2 # {{{
	(
		local check="Example 2"
		local -i rc=0 testresult=0

		local args

		set -- a1 a2 a3 a4 removeme
		response="$(
			set -e
			std::push -c args || true # For 'set -e'
			while [ ${#} -gt 1 ]
			do
				std::push args "${1}"
				shift
			done
			eval "set -- ${args}"
			echo "${*}"
		)" 2>/dev/null
		rc=${?}
		set -- "${fargs[@]}"

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
a1 a2 a3 a4
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "${expected}"
				info "Received:"
				output "${response}"
				testresult=1
			fi
		fi

		unset args

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	# Example 3 # {{{
	(
		local check="Example 3"
		local -i rc=0 testresult=0

		local files

		set -- a1 " a2 " "'a3'" '"a4"' '<a5' '>a6'
		response="$(
			set -e
			std::push -c files "${@}" && echo "su -c \"cat -- ${files}\""
		)" 2>/dev/null
		rc=${?}
		set -- "${fargs[@]}"

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
su -c "cat -- a1 ' a2 ' \'a3\' '"a4"' '<a5' '>a6'"
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "${expected}"
				info "Received:"
				output "${response}"
				testresult=1
			fi
		fi

		unset files

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	# Example 4 # {{{
	(
		local check="Example 4"
		local -i rc=0 testresult=0

		local v

		set -- source~1 'source 2' "source '3'"
		response="$(
			set -e
			std::push -c v cp -- "${@}" \~dest
			printf '%s\n' "${v}"
		)" 2>/dev/null
		rc=${?}
		set -- "${fargs[@]}"

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
cp -- source~1 'source 2' 'source '\'3\' '~dest'
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "${expected}"
				info "Received:"
				output "${response}"
				testresult=1
			fi
		fi

		unset v

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	# Example 5 # {{{
	(
		local check="Example 5"
		local -i rc=0 testresult=0

		response="$(
			# shellcheck disable=SC2034
			local data

			set -e

			function donothing() {
				:
			}
			function dosomething() {
				std::push data "item"
			}
			std::push -c data || true # For 'set -e'
			donothing
			# shellcheck disable=SC2016
			std::push data || echo 'nothing was pushed to $data in donothing'
			dosomething
			# shellcheck disable=SC2016
			std::push data || echo 'nothing was pushed to $data in dosomething'
		)" 2>/dev/null
		rc=${?}
		set -- "${fargs[@]}"

		if (( rc )); then
			error "${func} ${check} failed: ${rc}"
			testresult=1
		else
			std::define expected <<'EOF'
nothing was pushed to $data in donothing
EOF
			if [[ "${response:-}" == "${expected}" ]]; then
				info "${func} ${check}: okay"
			else
				error "${func} ${check}: failed"
				info "Expected:"
				output "${expected}"
				info "Received:"
				output "${response}"
				testresult=1
			fi
		fi

		exit ${testresult}
	)
	(( result += ${?} ))
	# }}}

	if (( result )); then
		error "${FUNCNAME[0]##*_} failed test-suite"
	else
		info "${FUNCNAME[0]##*_} passed test-suite"
	fi

	# Don't stomp std_ERRNO
	return ${result}
} # push::test # }}}

function wrap::test() { # {{{
	local response expected
	local -i result=0

	local func="std::wrap"

	local stdlib_want_wordwrap="${STDLIB_WANT_WORDWRAP:-}"
	local columns="${COLUMNS:-}"
	export STDLIB_WANT_WORDWRAP=1
	export COLUMNS=20

	# Test 1 # {{{
	(
		local check="Test 1"
		local -i rc=0

		response="$( std::wrap "Short output, no prefix" )"
#         1         2
#12345678901234567890
		std::define expected <<'EOF'
Short output, no 
prefix
EOF
		if [[ "${response:-}" == "${expected}" ]]; then
			info "${func} ${check}: okay"
		else
			error "${func} ${check}: failed"
			info "Expected:"
			output "$( sed "s/^/'/ ; s/$/'/" <<<"${expected}" )"
			info "Received:"
			output "$( sed "s/^/'/ ; s/$/'/" <<<"${response}" )"
			rc=1
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 2 # {{{
	(
		local check="Test 2"
		local -i rc=0

		response="$( std::wrap "PREFIX:" "Short output, with prefix" )"
#         1         2
#12345678901234567890
		std::define expected <<'EOF'
PREFIX: Short 
prefix: output, 
prefix: with prefix
EOF
		if [[ "${response:-}" == "${expected}" ]]; then
			info "${func} ${check}: okay"
		else
			error "${func} ${check}: failed"
			info "Expected:"
			output "$( sed "s/^/'/ ; s/$/'/" <<<"${expected}" )"
			info "Received:"
			output "$( sed "s/^/'/ ; s/$/'/" <<<"${response}" )"
			rc=1
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# Test 3 # {{{
	(
		local check="Test 3"
		local -i rc=0

		# shellcheck disable=SC2030
		export STDLIB_WANT_WORDWRAP=0

		response="$( std::wrap "PREFIX:" "Non-wrapped long output, with prefix" )"
		std::define expected <<'EOF'
PREFIX: Non-wrapped long output, with prefix
EOF
		if [[ "${response:-}" == "${expected}" ]]; then
			info "${func} ${check}: okay"
		else
			error "${func} ${check}: failed"
			info "Expected:"
			output "$( sed "s/^/'/ ; s/$/'/" <<<"${expected}" )"
			info "Received:"
			output "$( sed "s/^/'/ ; s/$/'/" <<<"${response}" )"
			rc=1
		fi

		exit ${rc}
	)
	(( result += ${?} ))
	# }}}

	# shellcheck disable=SC2031
	export STDLIB_WANT_WORDWRAP="${stdlib_want_wordwrap:-}"
	export COLUMNS="${columns:-}"

	if (( result )); then
		error "${FUNCNAME[0]##*_} failed test-suite"
	else
		info "${FUNCNAME[0]##*_} passed test-suite"
	fi

	# Don't stomp std_ERRNO
	return ${result}
} # wrap::test # }}}

# }}}

function main() { # {{{
	local wanted="${*:-}"
	local -i rc=0 debug=${std_DEBUG:-0}

	if [[ -z "${wanted:-}" ]]; then
		std::usage
	fi

	if grep -Eq ' (colour|all) ' <<<" ${wanted} "; then
		std_DEBUG=2
		output::test "${@:-}" ; rc+=${?}
		output
		std_DEBUG=${debug}
	fi

	if grep -Eq ' (emktemp|all) ' <<<" ${wanted} "; then
		emktemp::test "${@:-}" ; rc+=${?}
		output
	fi

	if grep -Eq ' (http|all) ' <<<" ${wanted} "; then
		http::test "${@:-}" ; rc+=${?}
		output
	fi

	if grep -Eq ' (mktemp|all) ' <<<" ${wanted} "; then
		mktemp::test "${@:-}" ; rc+=${?}
		output
	fi

	if grep -Eq ' (parseargs|all) ' <<<" ${wanted} "; then
		parseargs::test "${@:-}" ; rc+=${?}
		output
	fi

	if grep -Eq ' (push|all) ' <<<" ${wanted} "; then
		push::test "${@:-}" ; rc+=${?}
		output
	fi

	if grep -Eq ' (wrap|all) ' <<<" ${wanted} "; then
		wrap::test "${@:-}" ; rc+=${?}
		output
	fi

	# Don't stomp std_ERRNO
	return ${rc}
} # main # }}}

# Defined in stdlib.sh
# shellcheck disable=SC2034
std_USAGE="<colour|emktemp|http|mktemp|parseargs|push|wrap|all>"

main "${@:-}"

exit 0

# vi: set filetype=sh syntax=sh commentstring=#%s foldmarker=\ {{{,\ }}} foldmethod=marker colorcolumn=80 nowrap:
