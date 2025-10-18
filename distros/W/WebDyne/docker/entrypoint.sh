#!/bin/sh -x
set -e

# default to port 8080 if not specified
#
PORT="${PORT:-8080}"


# cpanfile exist ? If installdeps
#
if [ -f ./cpanfile ]; then
    cpanm --installdeps .
fi

# hands off to the real command overridden
#
if [ $# -gt 0 ]; then
  exec "$@"
else
  exec starman -MWebDyne --port "$PORT" $PERL_CARTON_PATH/bin/webdyne.psgi
fi
