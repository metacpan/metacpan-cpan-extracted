#!perl
#===============================================================================
#
# t/03_new_fh.t
#
# DESCRIPTION
#   Test script to check new_fh().
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
    use_ok('Win32::SharedFileOpen', qw(new_fh));
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

    $fh1 = new_fh();
    $ret = open $fh1, '>', $file1;
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'new_fh() - open') or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    ok(print($fh1 "$str\n"), 'new_fh() - print');

    $fh2 = new_fh();
    $ret = open $fh2, '>', $file2;
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'another new_fh() - open') or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    ok(print($fh2 "$str\n"), 'another new_fh() - print');

    close $fh2;
    is(-s $file2, $strlen + 2, 'fh2 worked');

    ok(print($fh1 "$str\n"), 'fh1 is still OK');

    close $fh1;
    is(-s $file1, ($strlen + 2) * 2, 'fh1 worked');

    unlink $file1;
    unlink $file2;
}

#===============================================================================
