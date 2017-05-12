#!perl
#===============================================================================
#
# t/10_fsopen_fh_leak.t
#
# DESCRIPTION
#   Test script to check if fsopen() leaks filehandles.
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

use Test::More tests => 513;

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    use_ok('Win32::SharedFileOpen', qw(:DEFAULT new_fh));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my($fh, $file, $ret, $errno, $lasterror);

    for my $i (1 .. 512) {
        $fh = new_fh();
        $file = "test$i.txt";
        $ret = fsopen($fh, $file, 'w', SH_DENYNO);
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, "filehandle $i works")
            ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");
        unlink $file;
    }
}

#===============================================================================
