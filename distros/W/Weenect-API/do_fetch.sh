#! /bin/bash

cd $(dirname $0) || exit 1

perl -Mlib=$HOME/lib/perl5 scripts/get_history.pl --dir=hist --quiet
