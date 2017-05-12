#!perl
#===============================================================================
#
# t/10_stat_fh_leak.t
#
# DESCRIPTION
#   Test script to check if stat(), lstat() or alt_stat() leak filehandles.
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

use Test::More tests => 6145;

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
    my($fh, $file, $errno, $lasterror, @stats, @lstats, @alt_stats);

    for my $i (1 .. 2048) {
        $file = "test$i.txt";
        open $fh, ">$file" or die "Can't create file '$file': $!\n";
        close $fh;

        @stats = Win32::UTCFileTime::stat $file;
        ($errno, $lasterror) = ($!, $^E);
        ok(scalar @stats, "stat() filehandle $i works") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        @lstats = Win32::UTCFileTime::lstat $file;
        ($errno, $lasterror) = ($!, $^E);
        ok(scalar @lstats, "lstat() filehandle $i works") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        @alt_stats = Win32::UTCFileTime::alt_stat($file);
        ($errno, $lasterror) = ($!, $^E);
        ok(scalar @alt_stats, "alt_stat() filehandle $i works") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        unlink $file;
    }
}

#===============================================================================
