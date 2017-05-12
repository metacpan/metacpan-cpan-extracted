#!perl
#===============================================================================
#
# t/01_imports_12.t
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

use Test::More tests => 9;

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    use_ok('Win32::SharedFileOpen', qw(:DEFAULT gensym new_fh :retry));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    ok(defined &main::fsopen, 'fsopen() is imported');
    ok(defined &main::sopen,  'sopen() is imported');
    ok(defined &main::gensym, 'gensym() is imported');
    ok(defined &main::new_fh, 'new_fh() is imported');
    ok(eval { O_APPEND(); 1 }, 'O_APPEND is imported');
    ok(eval { S_IREAD(); 1 }, 'S_IREAD is imported');
    ok(eval { SH_DENYNO(); 1 }, 'SH_DENYNO is imported');
    ok(eval { INFINITE(); 1 }, 'INFINITE is imported');
}

#===============================================================================
