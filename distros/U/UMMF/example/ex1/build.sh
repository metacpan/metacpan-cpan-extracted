#!/bin/sh
# $Id: build.sh,v 1.11 2006/05/14 01:40:03 kstephens Exp $
set -x

# Specify actions.
action=''
if [ $# -eq 0 ]
then
  action="$action build"
  action="$action deploy"
  action="$action store"
  action="$action retrieve";
fi
action="$action $*"

rm -f tmon.out

#export UMMF_PERL="${UMMF_PERL:-perl} -MDevel::Profiler"
#export UMMF_PERL="${UMMF_PERL:-perl} -d:DProf"

# Generate Perl code.
case "$action"
in
  *build*)
    rm -rf gen; ../../bin/ummf -e Perl -p Ex1 -o gen/perl Association_Storage_Example1.zuml
  ;;
esac

#export UMMF_PERL="${UMMF_PERL:-perl} -d" 
PERL5LIB="$HOME/local/src/tangram/t2/perl/blib/lib:$PERL5LIB"; export PERL5LIB

# Generate and deploy schema.
case "$action"
in
  *deploy*)
    ../../bin/ummf -I lib -I gen/perl -l Ex1::Ex1::Storage -m UMMF::Export::Perl::Tangram deploy --to-db gen
  ;;
esac

# Prepare application environment.
PERL5LIB="lib:gen/perl:../../gen/perl:../../lib/perl:$PERL5LIB"; export PERL5LIB

# Store objects.
case "$action"
in
  *store*)
    perl -d ./store.pl
  ;;
esac

# Retrieve objects.
case "$action"
in
  *retrieve*)
    perl -d ./retrieve.pl
  ;;
esac

