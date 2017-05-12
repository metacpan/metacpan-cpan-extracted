#!perl
#===============================================================================
#
# t/02_gensym.t
#
# DESCRIPTION
#   Test script to check gensym().
#
# COPYRIGHT
#   Copyright (C) 2002, 2004-2005, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Test::More tests => 8;

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    use_ok('Win32::SharedFileOpen', qw(gensym));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $file1  = 'test1.txt';
    my $file2  = 'test2.txt';
    my $str    = 'Hello, world.';
    my $strlen = length $str;

    my($fh1, $fh2, $ret, $errno, $lasterror);

    $fh1 = gensym();
    $ret = open $fh1, '>', $file1;
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'gensym() - open') or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    ok(print($fh1 "$str\n"), 'gensym() - print');

    $fh2 = gensym();
    $ret = open $fh2, '>', $file2;
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'another gensym() - open') or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    ok(print($fh2 "$str\n"), 'another gensym() - print');

    close $fh2;
    is(-s $file2, $strlen + 2, 'fh2 worked');

    ok(print($fh1 "$str\n"), 'fh1 is still OK');

    close $fh1;
    is(-s $file1, ($strlen + 2) * 2, 'fh1 worked');

    unlink $file1;
    unlink $file2;
}

#===============================================================================
