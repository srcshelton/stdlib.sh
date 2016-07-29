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
#
# We want the non if-then-else functionality here - the third element should be
# executed if either of the first two fail...
#
# N.B. The shellcheck 'source' option is only valid with shellcheck 0.4.0 and
#      later...
#
# shellcheck disable=SC2015
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

function push::test() { # {{{
	local -i rc=0 result=0
	# Test-cases from https://github.com/vaeth/push/blob/71794c14a709d4ef2816d76db89c2b7f41a0b650/README

	local response expected
	local -a fargs=( "${@:-}" )

	# Example 1 # {{{
	local foo
	response="$(
		set -e
		std::push -c foo 'data with special symbols like ()"\' "'another arg'"
		std::push foo further args
		eval "printf '%s\\n' ${foo}"
	)" 2>/dev/null
	rc=${?}

	if (( rc )); then
		error "std::push Example 1 failed: ${rc}"
		result=1
	else
		std::define expected <<'EOF'
data with special symbols like ()"\
'another arg'
further
args
EOF
		if [[ "${response:-}" == "${expected}" ]]; then
			info "std::push Example 1: okay"
		else
			error "std::push Example 1: failed"
			info "Expected:"
			output "${expected}"
			info "Received:"
			output "${response}"
			result=1
		fi
	fi
	unset foo
	# }}}

	# Example 2 # {{{
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
		error "std::push Example 2 failed: ${rc}"
		result=1
	else
		std::define expected <<'EOF'
a1 a2 a3 a4
EOF
		if [[ "${response:-}" == "${expected}" ]]; then
			info "std::push Example 2: okay"
		else
			error "std::push Example 2: failed"
			info "Expected:"
			output "${expected}"
			info "Received:"
			output "${response}"
			result=1
		fi
	fi
	unset args
	# }}}

	# Example 3 # {{{
	local files
	set -- a1 " a2 " "'a3'" '"a4"' '<a5' '>a6'
	response="$(
		set -e
		std::push -c files "${@}" && echo "su -c \"cat -- ${files}\""
	)" 2>/dev/null
	rc=${?}
	set -- "${fargs[@]}"

	if (( rc )); then
		error "std::push Example 3 failed: ${rc}"
		result=1
	else
		std::define expected <<'EOF'
su -c "cat -- a1 ' a2 ' \'a3\' '"a4"' '<a5' '>a6'"
EOF
		if [[ "${response:-}" == "${expected}" ]]; then
			info "std::push Example 3: okay"
		else
			error "std::push Example 3: failed"
			info "Expected:"
			output "${expected}"
			info "Received:"
			output "${response}"
			result=1
		fi
	fi
	unset files
	# }}}

	# Example 4 # {{{
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
		error "std::push Example 4 failed: ${rc}"
		result=1
	else
		std::define expected <<'EOF'
cp -- source~1 'source 2' 'source '\'3\' '~dest'
EOF
		if [[ "${response:-}" == "${expected}" ]]; then
			info "std::push Example 4: okay"
		else
			error "std::push Example 4: failed"
			info "Expected:"
			output "${expected}"
			info "Received:"
			output "${response}"
			result=1
		fi
	fi
	unset v
	# }}}

	# Example 5 # {{{
	local data
	response="$(
		set -e

		function donothing() {
			:
		}
		function dosomething() {
			std::push data "item"
		}
		std::push -c data || true # For 'set -e'
		donothing
		std::push data || echo 'nothing was pushed to $data in donothing'
		dosomething
		std::push data || echo 'nothing was pushed to $data in dosomething'
	)" 2>/dev/null
	rc=${?}
	set -- "${fargs[@]}"

	if (( rc )); then
		error "std::push Example 5 failed: ${rc}"
		result=1
	else
		std::define expected <<'EOF'
nothing was pushed to $data in donothing
EOF
		if [[ "${response:-}" == "${expected}" ]]; then
			info "std::push Example 5: okay"
		else
			error "std::push Example 5: failed"
			info "Expected:"
			output "${expected}"
			info "Received:"
			output "${response}"
			result=1
		fi
	fi
	unset data
	# }}}

	# Don't stomp std_ERRNO
	return ${result}
} # push::test # }}}

function parseargs::test() { # {{{
	local item1 item2 item3 unknown
	local -i std_PARSEARGS_parsed=0 result=0
	local -a args

	(
		args=( -item1 a -item2 b -item3 c )
		info "Stripping arguments from '${args[*]}' ..."

		std::parseargs --strip -- "${args[@]}"
		eval "set -- '$( std::parseargs --strip -- "${args[@]}" )'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	#output "\n"
	(
		args=( -item1 a b -item2 c d -item3 e )
		info "Stripping arguments from '${args[*]}' ..."

		std::parseargs --strip -- "${args[@]}"
		eval "set -- '$( std::parseargs --strip -- "${args[@]}" )'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	#output "\n"
	(
		args=( -item1 a -item2 b -item3 c )
		info "Argument-parsing '${args[*]}' ..."

		std::parseargs --single --permissive --var unknown -- "${args[@]}"
		eval "$( std::parseargs --single --permissive --var unknown -- "${args[@]}" )"
		echo "item1 is '${item1:-}', '${item1[*]:-}'"
		echo "item2 is '${item2:-}', '${item2[*]:-}'"
		echo "item3 is '${item3:-}', '${item3[*]:-}'"
		echo "unknown is '${unknown:-}', '${unknown[*]:-}'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	#output "\n"
	(
		args=( -item1 a b -item2 c d -item3 e )
		info "Argument-parsing '${args[*]}' with --single ..."

		std::parseargs --single --permissive --var unknown -- "${args[@]}"
		eval "$( std::parseargs --single --permissive --var unknown -- "${args[@]}" )"
		echo "item1 is '${item1:-}', '${item1[*]:-}'"
		echo "item2 is '${item2:-}', '${item2[*]:-}'"
		echo "item3 is '${item3:-}', '${item3[*]:-}'"
		echo "unknown is '${unknown:-}', '${unknown[*]:-}'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	#output "\n"
	(
		args=( -item1 a b -item2 c d -item3 e )
		info "Argument-parsing '${args[*]}' without --single ..."

		std::parseargs --permissive --var unknown -- "${args[@]}"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		echo "item1 is '${item1:-}', '${item1[*]:-}'"
		echo "item2 is '${item2:-}', '${item2[*]:-}'"
		echo "item3 is '${item3:-}', '${item3[*]:-}'"
		echo "unknown is '${unknown:-}', '${unknown[*]:-}'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	#output "\n"
	(
		args=( -item1 "a b" c -item2 d "e f" -item3 "g h" "i j" )
		info "Argument-parsing '${args[*]}' without --single ..."

		std::parseargs --permissive --var unknown -- "${args[@]}"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		echo "item1 is '${item1:-}', '${item1[*]:-}'"
		echo "item2 is '${item2:-}', '${item2[*]:-}'"
		echo "item3 is '${item3:-}', '${item3[*]:-}'"
		echo "unknown is '${unknown:-}', '${unknown[*]:-}'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	#output "\n"
	(
		args=( a )
		info "Argument-parsing '${args[*]}' ..."

		std::parseargs --permissive --var unknown -- "${args[@]}"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]}" )"
		echo "unknown is '${unknown:-}', '${unknown[*]:-}'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	#output "\n"
	(
		args=()
		info "Argument-parsing '${args[*]:-}' ..."

		std::parseargs --permissive --var unknown -- "${args[@]:-}"
		eval "$( std::parseargs --permissive --var unknown -- "${args[@]:-}" )"
		echo "unknown is '${unknown:-}', '${unknown[*]:-}'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)
	#output "\n"
	std::colour -type warn -colour red "WARN: Expected failure (without --permissive):"
	(
		args=( a )
		info "Argument-parsing '${args[*]}' ..."

		std::parseargs --var unknown -- "${args[@]}"
		eval "$( std::parseargs --var unknown -- "${args[@]}" )"
		echo "unknown is '${unknown:-}', '${unknown[*]:-}'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	#output "\n"
	std::colour -type warn -colour red "WARN: Expected failure (without --permissive):"
	(
		args=()
		info "Argument-parsing '${args[*]:-}' ..."

		std::parseargs --var unknown -- "${args[@]:-}"
		eval "$( std::parseargs --var unknown -- "${args[@]:-}" )"
		echo "unknown is '${unknown:-}', '${unknown[*]:-}'"

		if ! [[ -n "${std_PARSEARGS_parsed:-}" ]]; then
			warn "std_PARSEARGS_parsed not set!"
		else
			if ! (( std_PARSEARGS_parsed )); then
				output "std_PARSEARGS_parsed='${std_PARSEARGS_parsed}'"
			fi
		fi
	)

	# Don't stomp std_ERRNO
	return ${result}
} # parseargs::test # }}}

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

# }}}

function main() {
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

	if grep -Eq ' (push|all) ' <<<" ${wanted} "; then
		push::test "${@:-}" ; rc+=${?}
		output
	fi

	if grep -Eq ' (parseargs|all) ' <<<" ${wanted} "; then
		parseargs::test "${@:-}" ; rc+=${?}
		output
	fi

	if grep -Eq ' (http|all) ' <<<" ${wanted} "; then
		http::test "${@:-}" ; rc+=${?}
		output
	fi

	# Don't stomp std_ERRNO
	return ${rc}
} # main

# Defined in stdlib.sh
# shellcheck disable=SC2034
std_USAGE="<parseargs|colour|http|all>"

main "${@:-}"

exit 0

# vi: set filetype=sh syntax=sh commentstring=#%s foldmarker=\ {{{,\ }}} foldmethod=marker colorcolumn=80 nowrap:
