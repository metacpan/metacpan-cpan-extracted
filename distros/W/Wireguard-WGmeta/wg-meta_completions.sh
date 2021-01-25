#/usr/bin/env bash

MAIN_COMMANDS="set show enable disable addpeer apply help"

_wg-meta_main_completions() {
  COMPREPLY=($(compgen -W "${MAIN_COMMANDS}" "${COMP_WORDS[1]}"))
}

_wg-meta_interface_completions() {
  local WG_INTERFACES=$(ip link show type wireguard | grep -o '[[:digit:]]: .*:' | sed 's/^[0-9]: //g' | sed 's/:$//g')
  COMPREPLY=($(compgen -W "${WG_INTERFACES}" "${COMP_WORDS[2]}"))
}

_wg-meta_complete() {
  case $COMP_CWORD in
  1)
    _wg-meta_main_completions
    ;;
  2)
    _wg-meta_interface_completions
    ;;
  esac
  return 0
}

complete -F _wg-meta_complete wg-meta
