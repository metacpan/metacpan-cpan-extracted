#!/bin/bash -f
#shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

cd "${SCRIPT_DIR}" || exit 1
export PERL5LIB=${SCRIPT_DIR}/lib:${SCRIPT_DIR}:${PERL5LIB}
prove "t"
