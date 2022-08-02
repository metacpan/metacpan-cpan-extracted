# test/more.bash - Complete TAP test framework for Bash
#
# Copyright (c) 2013-2020. Ingy döt Net.

set -e -u -o pipefail

# shellcheck disable=2034

source test-tap.bash

tap:init "$@"

plan() { tap:plan tests "$@"; }
pass() { tap:pass "$@"; }
fail() { tap:fail "$@"; }
diag() { tap:diag "$@"; }
note() { tap:note "$@"; }
done-testing() { tap:done-testing "$@"; }
bail-out() { tap:bail-out "$@"; }
bail-on-fail() { tap:bail-on-fail "$@"; }

is() {
  local got=$1 want=$2 label=${3-}
  if [[ $got == "$want" ]]; then
    tap:pass "$label"
  else
    tap:fail "$label" more:is-fail
  fi
}

more:is-fail() {
  local Test__Tap_CALL_STACK_LEVEL=
  Test__Tap_CALL_STACK_LEVEL=$(( Test__Tap_CALL_STACK_LEVEL + 1 ))
  if [[ $want =~ $'\n' ]]; then
    echo "$got" > /tmp/got-$$
    echo "$want" > /tmp/want-$$
    diff -u /tmp/{want,got}-$$ >&2 || true
    wc /tmp/{want,got}-$$ >&2
    rm -f /tmp/{got,want}-$$
  else
    tap:diag "\
    got: '$got'
  expected: '$want'"
  fi
}

isnt() {
  local Test__Tap_CALL_STACK_LEVEL=
  Test__Tap_CALL_STACK_LEVEL=$(( Test__Tap_CALL_STACK_LEVEL + 1 ))
  local got=$1 dontwant=$2 label=${3-}
  if [[ $got != "$dontwant" ]]; then
    tap:pass "$label"
  else
    tap:fail "$label" more:isnt-fail
  fi
}

more:isnt-fail() {
    tap:diag "\
      got: '$got'
   expected: anything else"
}

ok() {
  if (exit "${1:-$?}"); then
    tap:pass "${2-}"
  else
    tap:fail "${2-}"
  fi
}

like() {
  local got=$1 regex=$2 label=${3-}
  regex=${regex#/}
  regex=${regex%/}
  if [[ $got =~ $regex ]]; then
    tap:pass "$label"
  else
    tap:fail "$label" more:like-fail
  fi
}

more:like-fail() {
    tap:diag "Got: '$got'"
}

unlike() {
  local got=$1 regex=$2 label=${3-}
  if [[ ! $got =~ $regex ]]; then
    tap:pass "$label"
  else
    tap:fail "$label" more:unlike-fail
  fi
}

more:unlike-fail() {
    tap:diag "Got: '$got'"
}

cmp-array() {
    local arrayname="$1[@]"
    local expname="$2[@]"
    local label=${3-}

    local array=("${!arrayname}")
    local expected=("${!expname}")

    is "$(printf "%s\n" "${array[@]}")" \
      "$(printf "%s\n" "${expected[@]}")" \
      "$label"
}
