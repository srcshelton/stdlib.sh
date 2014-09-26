Standard functions library for bash
===================================

Even though no POSIX-compatible shell is likely to win any performance awards,
the capabilities of modern shells - especailly `bash-4` and above - now allow
significant power and flexibility.  However, many shell-scripts remain
afterthoughts, quickly thrown together without any consideration of- or
adherence to- any particular standards.  Due to the lack of any widely adopted
standard functions, many scripts either lack even the most basic of error-
handling techniques, or spend much time re-implmenting boiler-plate code.  This
library is intended to live in `/usr/local/lib`, and either be included in any
scripts which wish to make use of the standardised functions - or even sourced
from `~/.bashrc` in order to speed individual script execution.

Orientation
===========

`stdlib.sh` requires at least `bash-2.02` (for `[[ ... ]]` in-process conditional
evaluation), and several functions use the `=~` regular-expression match
operator introduced in `bash-3`.  If `bash-4` features such as associative
arrays are available, then the environment variable `STDLIB_HAVE_BASH_4` is set
on load - see below.

Coding Standards
================

All scripts should, following the interpreter line at the very top of the file,
include the `stdlib.sh` loader code from the top of `/usr/local/lib/stdlib.sh`.
stdlib will only execute itself if its functions aren't already initialised.
On load, `stdlib.sh` invokes `set -u` which causes bash to abort execution if
a run-time attempt is made to address an unbound variable.  Because of this,
any third-party scripts should be sourced _before_ `stdlib.sh` is loaded -
however, since the unbound-variable checking is perfomed at run-time only, any
functions in sourced scripts may still trigger an unbound variable error on
execution.

Only global variables (in ALLCAPS, by convention) should be defined outside of
any function, and should follow the `stdlib.sh` inclusion code.  The main-loop
of the script's function should be contained within a `main()` function, which
should in turn call other functions as appropriate.  All other variables should
be declared 'local' within the function in which they are used.  Other useful
declarations are:

* `local -i` : Define an integer variable, which accepts only numbers, defaults
  to value `0`, and will never return a value of true in response to `test -z`;

* `local -u` : Define an upper-case variable, where any assigned value is
  automatically converted to upper-case;

* `local -l` : Define a lower-case variable, where any assigned value is
  automatically converted to lower-case;

* `local -a` : Define an array variable;

* `local -A` : Defined an associative array;

For top-level global values outside of functions, `declare` can be used in
place of `local`.  Top-level variables must stil be `export`ed in order to be
visible to sub-shells.

`stdlib.sh` is designed on the principal that successful function execution
elicits a return-code of zero, whilst non-zero indicates an error.  Calling
`exit` (or `die`) is generally avoided in functions, leaving the caller to
decide on the severity of a failure.  Code considered unreachable, if ever
executed, should return a canary value of `255`.  Only values between `0` and
`255` are valid return-codes - returning a negative value, sometimes seen in
code written by Java programmers particularly, will actually return `256` less
the absolute value of the return code.

It is suggested that all variables be enclosed within braces, and also
double-quoted unless defined as a numeric value with `local -i` or
`declare -i`.  The exception to this is where a variable is used in place of a
comment, where braces should be omitted in order to differentiate commands from
values.

```bash
local string="text"
output "${string:-}"

local -i rc=0
return ${rc}

declare DEBUG_RM="echo rm"
$DEBUG_RM "${files[@]}"
```

Functions
=========

| Function                | Description                                                                                    |
|-------------------------|------------------------------------------------------------------------------------------------|
| `output()`              | An alias for `echo`, used to indicate user-visible output                                      |
| `respond()`             | An alias for `echo`, used to indicate response feedback                                        |
| `std::cleanup()`        | Remove any temporary files created by the `mktemp` functions or added by `std::garbagecollect` |
| `std::usage-message()`  | Provide custom help-text where `${std_USAGE}` is not sufficient                                |
| `std::usage()`          | Output help text from `${std_USAGE}` or std::usage-message()                                   |
| `std::wrap()`           | Format text to wrap to the width of the console at a word-end - N.B. Requires 'export COLUMNS' |
| `std::log()`            | Output text to console, file, or syslog                                                        |
| `die()`                 | Output text in a standard format and exit with a failure code                                  |
| `error()`               | Output text in a standard format                                                               |
| `warn()`                | Output text in a standard format                                                               |
| `note()`                | Output text in a standard format                                                               |
| `notice()`              | Output text in a standard format                                                               |
| `info()`                | Output text in a standard format                                                               |
| `debug()`               | Output text in a standard format                                                               |
| `symerror()`            | errno: Provide symbol name (such as '`EERROR`') for specified code                             |
| `errsymbol()`           | errno: Provide code for specified symbol                                                       |
| `strerror()`            | errno: Provide description string for most recent or specified code                            |
| `std::garbagecollect()` | Add additional files for automatic removal on exit                                             |
| `std::mktemp()`         | OS-neutral standard `mktemp(1)` replacement, with garbage collection                           |
| `std::emktemp()`        | Enhanced `mktemp(1)` replacemnt with improved syntax                                           |
| `std::push()`           | `Push()` implementation - see Martin Väth's original [here](https://github.com/vaeth/push)     |
| `std::readlink()`       | Basic OS-neutral `readlink(1)` stand-in                                                        |
| `std::define()`         | Improved HEREDOC support, without the need to invoke `cat`                                     |
| `std::formatlist()`     | Return an English-formatted list with Oxford comma                                             |
| `std::vcmp()`           | Compare two specified versions, or output a list of versions and succeed if the list was sorted|
| `std::requires()`       | Declare script command requirements/dependencies                                               |
| `std::capture()`        | Capture the output- or error- stream of a command                                              |
| `std::ensure()`         | Exit with a specified error message if a command fails                                         |
| `std::silence()`        | Execute a command and drop all output (e.g. `>/dev/null 2>&1`)                                 |
| `std::getfilesection()` | Retrieve a single section from a Windows-style .ini file with square-bracketed section titles  |
| `std::parseargs()`      | Allow functions to accept named parameters with only minor code-changes                        |
| `std::configure()`      | Export variables containing the standard system paths as used by `configure` scripts           |

