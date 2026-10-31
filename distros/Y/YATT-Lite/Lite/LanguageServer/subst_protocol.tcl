#!/usr/bin/tclsh

package require json::write

set realScriptFn [file normalize [info script]]
set scriptDir [file dirname $realScriptFn]

set parser   $scriptDir/SpecParser.pm
set cgen     $scriptDir/Spec2Types.pm
set targetFn $scriptDir/Protocol.pm
set specFn   $scriptDir/specification.md

#========================================
package require cmdline

set ::globalOptionList {
    {n "dry-run"}
    {w "write"}
    {P.arg "" "run parser pipline until N"}
}
array set ::opts [cmdline::getoptions ::argv $::globalOptionList]

proc RUN args {
    puts stderr "# $args"
    if {$::opts(n)} return
    # リダイレクトが指定されていない時は stdout へリダイレクト。末尾のみ認識。
    if {[lindex $args end-1] ni {">" ">@" ">>"}} {
        lappend args >@ stdout
    }
    =RUN {*}$args
}

proc =RUN args {
    exec -ignorestderr {*}$args 2>@ stderr
}

#========================================

proc parser_level n {
    expr {$::opts(P) eq ""
          || $n < $::opts(P)}
}

proc parse_spec {specFn args} {
    set P []
    lappend P $::parser {*}[if {[parser_level 1]} {
        list --output=json
    }] extract_codeblock typescript $specFn
    if {[parser_level 1]} {
        lappend P | $::parser cli_xargs_json extract_statement_list
    }
    if {[parser_level 2]} {
        lappend P | grep -v {interface ParameterInformation}
    }
    if {[parser_level 3]} {
        lappend P | $::parser cli_xargs_json --slurp --single tokenize_statement_list
    }
    if {[parser_level 4]} {
        lappend P | $::parser cli_xargs_json --slurp --single parse_statement_list
    }

    =RUN {*}$P {*}$args
}

proc extract_previous_types fn {
    set fh [open $fn]
    set types ""
    for {set flipflop 0} {[gets $fh line] >= 0} {
        if {$flipflop} {incr flipflop}
    } {
        if {!$flipflop && [regexp "#==BEGIN_GENERATED" $line]} {
            incr flipflop
        } elseif {$flipflop && [regexp "#==END_GENERATED" $line]} {
            set flipflop 0
        }
        if {$flipflop} {
            if {[regexp "# make_typedefs_from: (.*)" $line -> types]} {
                break
            }
        }
    }
    close $fh
    return $types
}

proc generate {defsList args} {
    set jsonArray [json::write array {*}$defsList]
    RUN $::cgen --output=pairlist make_typedefs_from $jsonArray {*}$args
}

proc read_template fn {
    set fh [open $fn]
    array set buffer {}
    set state 0

    for {set flipflop 0; set end 0} {[gets $fh line] >= 0} {
        if {$end} {set flipflop 0} elseif {$flipflop} {incr flipflop}
    } {
        # puts "($state,$flipflop) $line"

        if {!$flipflop && [regexp "#==BEGIN_GENERATED" $line]} {
            incr flipflop
        } elseif {$flipflop && [regexp "#==END_GENERATED" $line]} {
            set end 1
            set flipflop 0
            incr state
        }

        if {!$flipflop || $flipflop == 1} {
            append buffer($state) $line\n
        }

    }
    close $fh
    set result []
    for {set i 0} {$i <= $state} {incr i} {
        if {[info exists buffer($i)]} {
            lappend result $buffer($i)
        }
    }
    set result
}

#========================================

if {$opts(P) ne ""} {
    parse_spec $specFn >@ stdout
} else {
    set outFH [if {$opts(w)} {
        set tmpFn $targetFn.[pid]
        open $tmpFn w
    } else {
        list stdout
    }]

    lassign [read_template $targetFn] header footer

    puts -nonewline $outFH $header

    set newTypes [list {*}[extract_previous_types $targetFn] \
                      {*}$::argv]

    puts $outFH "# make_typedefs_from: $newTypes"

    generate [split [parse_spec $specFn] \n] \
        {*}$newTypes >@ $outFH

    puts -nonewline $outFH $footer

    if {[info exists tmpFn]} {
        file rename -force $tmpFn $targetFn
    }
}
