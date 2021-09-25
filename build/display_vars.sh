#!/bin/bash
set -e

heading () {
  echo >&2 \[ '$MODULE' \] \|\| $@
}
export -f heading

var () {
  arg1=$@
  local token=${1:?} #
  expandVar='expanded=${'${token}'}; [ "${expanded}" == "" ] || echo '$arg1'=\""${'${token}'}"\" || echo '$arg1'='
  /bin/bash -c "$expandVar" -- 'arg1'
}
export -f var

info () {
  echo -e "[  INFO ] - $1"
}
export -f info

fail () {
  echo -e "[  FAIL ] - $1"
}
export -f fail


export ENV_TAG_SUFFIX="PEAK-AUTO-VERSION"
