#!/bin/zsh

emulate -L zsh

set -e

realScriptFn=$(readlink -f $0)
scriptDir=$realScriptFn:h

parser=$scriptDir/SpecParser.pm
cgen=$scriptDir/Spec2Types.pm
targetFn=$scriptDir/Protocol.pm

#========================================

function usage {
    if ((ARGC)); then print -- $* 1>&2; fi
    cat 1>&2 <<EOF
Usage: ${realScriptFn:t} [opts] specification.md TYPE_NAME...

Options:

-n  dryrun
-w  write
EOF
    exit 1
}

#========================================
o_dryrun=()
function x {
    if (($#o_dryrun)); then
        print 1>&2 "#" ${(q-)argv}
        return;
    fi
    "$@"
}

zparseopts -D -K n=o_dryrun w=o_write d=o_debug x=o_xtrace

if (($#o_xtrace)); then set -x; fi

((ARGC >= 2)) || usage

specFn=$1; shift

[[ -r $specFn ]] || usage "Can't read specfile $specFn"

function emit_body {

    () {
        local defsFn=$1; shift
        
        print "# make_typedefs_from: $*"
        perl $o_debug $cgen --output=pairlist make_typedefs_from $defsFn "$@"

    } =(
        $parser extract_codeblock typescript $specFn|
            $parser cli_xargs_json extract_statement_list|
            grep -v 'interface ParameterInformation'|
            $parser cli_xargs_json --slurp --single tokenize_statement_list|
            $parser cli_xargs_json --slurp --single parse_statement_list
    ) "$@"

}

function emit {
    local bodyFn=$1; shift
    local perl_opts
    if (($#o_write)); then
        perl_opts+=(-i.bak)
    fi
    x perl -MIO::All $perl_opts -nl -e 'BEGIN {$SRCFN = shift}' -e '
if (my $line = /^\s*#==BEGIN_GENERATED/ .. /^\s*#==END_GENERATED/) {
  if ($line == 1) {
    print;
    print io->file($SRCFN)->slurp;
  } elsif ($line =~ /E0/) {
    print;
  }
} else {
  print;
}' $bodyFn $targetFn 
}

emit =(emit_body "$@")
