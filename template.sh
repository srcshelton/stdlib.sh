#! /usr/bin/env bash

###############################################################################
#
# Initialise stdlib.sh...
#
###############################################################################

# {{{

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

# std_RELEASE was only added in release 1.3, and std::vcmp appeared immediately
# after in release 1.4...
if [[ "${std_RELEASE:-1.3}" == "1.3" ]] || std::vcmp "${std_RELEASE}" -lt "2.0.0"; then
	die "stdlib is too old - please update '${std_LIBPATH}/${std_LIB}' to at least v2.0.0" # for API 2
elif std::vcmp "${std_RELEASE}" -lt "2.0.4"; then
	warn "stdlib is outdated - please update '${std_LIBPATH}/${std_LIB}' to at least v2.0.4" # for std_LASTOUTPUT
fi

# }}}

###############################################################################
#
# Set environment...
#
###############################################################################

std_DEBUG="${DEBUG:-0}"
std_TRACE="${TRACE:-0}"

#std_LOGFILE='/dev/null'

###############################################################################
#
# Executable script follows...
#
###############################################################################

function main() { # {{{
	local -a args=( "${@:-}" )

	(( std_TRACE )) && set -o xtrace

	:

	(( std_TRACE )) && set +o xtrace
} # }}} # main

main "${@:-}"

exit ${?}

# vi: set syntax=sh commentstring=#%s foldmarker=\ {{{,\ }}} foldmethod=marker colorcolumn=80:
