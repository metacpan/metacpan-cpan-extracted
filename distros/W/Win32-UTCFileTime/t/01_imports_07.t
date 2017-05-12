#!perl
#===============================================================================
#
# t/01_imports_09.t
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
    use_ok('Win32::UTCFileTime', qw(:globally :DEFAULT));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    ok( defined &main::stat, 'stat is imported');
    ok( defined &main::lstat, 'lstat is imported');
    ok( defined &main::utime, 'utime is imported');
    ok(!defined &main::alt_stat, 'alt_stat is not imported');
    ok( defined &CORE::GLOBAL::stat, 'stat is globally overridden');
    ok( defined &CORE::GLOBAL::lstat, 'lstat is globally overridden');
    ok( defined &CORE::GLOBAL::utime, 'utime is globally overridden');
    ok(!defined &CORE::GLOBAL::alt_stat, 'slt_tat is not globally overridden');
}

#===============================================================================
