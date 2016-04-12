#!/bin/bash

# Copyright 2013-2016 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2
#
# stdlib-test.sh - basic tests and checks for stdlib.sh

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
[[ -r "${std_LIBPATH}/${std_LIB}" ]] && source "${std_LIBPATH}/${std_LIB}" || {
	echo >&2 "FATAL:  Unable to source ${std_LIB} functions"
	exit 1
}


(( std_TRACE )) && set -o xtrace


 function main() { # {{{

	info "Info"
	notice "Notice"
	note "Note"

	warn "Warning"
	error "Error"
	#die "Die"

	waitForRes "Executing foo1"
	evalRes "echo 'foo' > /dev/null"
	checkRes f $? "good"

	waitForRes "Executing foo2"
	evalRes "echo 'foo' > /dev/null"
	checkRes w 1 "not so good"

	waitForRes "Executing foo3"
	evalRes "echo 'foo' > /dev/null"
	checkRes k 1 "not good"

	waitForRes "Executing foo4"
	evalRes "echo 'foo' > /dev/null"
	checkRes f 1 "bad"

 } # main # }}}

 main "${@:-}"

 exit 0

 # vi: set filetype=sh syntax=sh commentstring=#%s foldmarker=\ {{{,\ }}} foldmethod=marker colorcolumn=80 nowrap:
