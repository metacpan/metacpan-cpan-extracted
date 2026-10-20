# NAME

ZX81::Tape - Create ZX81 tape image files

# SYNOPSIS

    use ZX81::Tape qw(make_p dump_p list_p);

    make_p($basic_filename, $p_filename);
    dump_p($p_filename[, $dump_filename]);
    list_p($p_filename[, $bas_filename]);

# DESCRIPTION

This module converts a BASIC source file to a ZX81 .p tape file.

# FUNCTIONS

## make\_p

    make_p($basic_filename, $p_filename);

Reads the given source BASIC file and builds a binary tape image file.p\_filename 
with the given file name.

## dump\_p

    dump_p($p_filename[, $dump_filename]);

Reads the given binary tape image file and dumps its contents to the 
standard output or a specified file with the given file name.

## list\_p

    list_p($p_filename[, $bas_filename]);

Reads the given binary tape image file and generates a .bas text that 
can be compiled back to the same .p result.

# BASIC SYNTAX

All ZX81 BASIC keywords are accepted. The escape sequences supported by 
[https://freestuff.grok.co.uk/zxtext2p/index.html](https://freestuff.grok.co.uk/zxtext2p/index.html) are also accepted.

Line numbers are optional and the source program is numbered before conversion
to the tape format. The start line number is 10 by default and the increment
between consecutive lines is also 10 by default. A line with a line number
resets the numbering from there on. Line numbers from 0 to 9999 are accepted.

BASIC code can use numbers in hexadecimal with the notation $hh and 0xhh.

## LABELS

Labels can be written before the BASIC statement as '@' NAME ':', and can be
referenced as '@' NAME, e.g.

    @LOOP: PRINT "HELLO"
           GOTO @LOOP

The address of the line can be referenced as '&' NAME, e.g.

    @MCODE: REM \C9
            PRINT USR &MCODE

## PRAGMAS

### #AUTOSTART

    #AUTOSTART=[0|1]

If set to 1, the BASIC program will start automatically when the tape is 
loaded.

### #AUTOSTART\_LINE

    #AUTOSTART=[LINE_NUMBER]

If AUTOSTART\_LINE is set, sets the line number where the BASIC program
will start automatically when the tape is loaded, defaults to the first
line of the BASIC program.

### #INCREMENT

    #INCREMENT=[INCREMENT]

If INCREMENT is set, specifies the line number increment between consecutive
lines in the BASIC program, defaults to 10. Can be entered multiple times in
the source file, and takes effect from the line where it is set.

### #REMINVERT

    #REMINVERT=[0|1]

If set to 1, inverts the REM statements in the BASIC program. Only applies
to REM statements that do not contain binary data.

### #FAST

    #FAST=[0|1]

If set to 1, sets the computer in FAST mode.

### #VARS

    #VARS A=123
    #VARS I=0,10,1,20
    #VARS S$="HELLO"
    #VARS M(2,3)=11,12,13,21,22,23
    #VARS M$(2,3,2)="AA","AB","AC","BA","BB","BC"

Specifies the initial values of variables in the BASIC program. I in the
example above is a loop variable with value 0, limit 10, step 1 and line 
number 20.

### #DFILE

    #DFILE="LINE 1"
    #DFILE="LINE 2"
    ...

Defines the initial contents of the display file. Each line of the display
file is defined by a separate #DFILE pragma.

### #DFILE\_COLLAPSED

    #DFILE_COLLAPSED=[0|1]

Saves the display file in collapsed form.

### #ASM

    #ASM
    start:
        ld bc, 1234
        ret
    #ENDASM
        PRINT USR &start

The lines between #ASM and #ENDASM are collected and assembled with an ORG
of 0x4082, and a 0 REM line is created with the binary image of the assembled
code. BASIC can use ASM labels via '&' NAME.

# SEE ALSO

[ZX81](https://metacpan.org/pod/ZX81)
[https://freestuff.grok.co.uk/zxtext2p/index.html](https://freestuff.grok.co.uk/zxtext2p/index.html)

# AUTHOR

Paulo Custodio

# COPYRIGHT AND LICENSE

Copyright (C) 2026 Paulo Custodio.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
