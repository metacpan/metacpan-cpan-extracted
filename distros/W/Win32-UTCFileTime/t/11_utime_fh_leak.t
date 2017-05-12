#!perl
#===============================================================================
#
# t/11_utime_fh_leak.t
#
# DESCRIPTION
#   Test script to check if utime() leaks filehandles.
#
# COPYRIGHT
#   Copyright (C) 2012, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Test::More tests => 2049;

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    use_ok('Win32::UTCFileTime');
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my($fh, $file, $time, $ret, $errno, $lasterror);

    for my $i (1 .. 2048) {
        $file = "test$i.txt";
        open $fh, ">$file" or die "Can't create file '$file': $!\n";
        close $fh;
        $time  = time;

        $ret = utime $time, $time, $file;
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, "utime() filehandle $i works") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        unlink $file;
    }
}

#===============================================================================
