#!perl
#===============================================================================
#
# t/01_imports_07.t
#
# DESCRIPTION
#   Test script to check import options.
#
# COPYRIGHT
#   Copyright (C) 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Config qw(%Config);
use Test::More tests => 23;

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    use_ok('Win32::SharedFileOpen', qw(O_APPEND));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $bcc = $Config{cc} =~ /bcc32/io;

    ok(!defined &main::fsopen, 'fsopen() is not imported');
    ok(!defined &main::sopen,  'sopen() is not imported');
    ok(!defined &main::gensym, 'gensym() is not imported');
    ok(!defined &main::new_fh, 'new_fh() is not imported');
    ok( eval { O_APPEND(); 1 }, 'O_APPEND is imported');
    ok(!eval { O_BINARY(); 1 }, 'O_BINARY is not imported');
    ok(!eval { O_CREAT(); 1 }, 'O_CREAT is not imported');
    ok(!eval { O_EXCL(); 1 }, 'O_EXCL is not imported');
    ok(!eval { O_NOINHERIT(); 1 }, 'O_NOINHERIT is not imported');
    SKIP: {
        skip "Borland C RTL doesn't support O_RANDOM", 1 if $bcc;
        ok(!eval { O_RANDOM(); 1 }, 'O_RANDOM is not imported');
    }
    ok(!eval { O_RAW(); 1 }, 'O_RAW is not imported');
    ok(!eval { O_RDONLY(); 1 }, 'O_RDONLY is not imported');
    ok(!eval { O_RDWR(); 1 }, 'O_RDWR is not imported');
    SKIP: {
        skip "Borland C RTL doesn't support O_SEQUENTIAL", 1 if $bcc;
        ok(!eval { O_SEQUENTIAL(); 1 }, 'O_SEQUENTIAL is not imported');
    }
    SKIP: {
        skip "Borland C RTL doesn't support O_SHORT_LIVED", 1 if $bcc;
        ok(!eval { O_SHORT_LIVED(); 1 }, 'O_SHORT_LIVED is not imported');
    }
    SKIP: {
        skip "Borland C RTL doesn't support O_TEMPORARY", 1 if $bcc;
        ok(!eval { O_TEMPORARY(); 1 }, 'O_TEMPORARY is not imported');
    }
    ok(!eval { O_TEXT(); 1 }, 'O_TEXT is not imported');
    ok(!eval { O_TRUNC(); 1 }, 'O_TRUNC is not imported');
    ok(!eval { O_WRONLY(); 1 }, 'O_WRONLY is not imported');
    ok(!eval { S_IREAD(); 1 }, 'S_IREAD is not imported');
    ok(!eval { SH_DENYNO(); 1 }, 'SH_DENYNO is not imported');
    ok(!eval { INFINITE(); 1 }, 'INFINITE is not imported');
}

#===============================================================================
