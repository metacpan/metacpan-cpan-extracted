#!perl
#===============================================================================
#
# t/04_file_mode.t
#
# DESCRIPTION
#   Test script to check getting file mode.
#
# COPYRIGHT
#   Copyright (C) 2003-2005, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Test::More tests => 31;

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
    my @files = map { "test.$_" } qw(txt exe bat com cmd);

    my($fh, @cstats, @rstats, @astats);

    foreach my $file (@files) {
        open $fh, ">$file" or die "Can't create file '$file': $!\n";
        close $fh;
    }

    foreach my $file (@files) {
        chmod 0777, $file;
        @cstats = CORE::stat $file;
        @rstats = Win32::UTCFileTime::stat $file;
        @astats = Win32::UTCFileTime::alt_stat($file);
        is($rstats[2], $cstats[2],
           "stat() works for executable file $file");
        is($astats[2], $cstats[2],
           "alt_stat() works for executable file $file");

        @cstats = CORE::lstat $file;
        @rstats = Win32::UTCFileTime::lstat $file;
        is($rstats[2], $cstats[2],
           "lstat() works for executable file $file");

        chmod 0444, $file;
        @cstats = CORE::stat $file;
        @rstats = Win32::UTCFileTime::stat $file;
        @astats = Win32::UTCFileTime::alt_stat($file);
        is($rstats[2], $cstats[2],
           "stat() works for read-only file $file");
        is($astats[2], $cstats[2],
           "alt_stat() works for read-only file $file");

        @cstats = CORE::lstat $file;
        @rstats = Win32::UTCFileTime::lstat $file;
        is($rstats[2], $cstats[2],
           "lstat() works for read-only file $file");
    }

    foreach my $file (@files) {
        chmod 0777, $file;
        unlink $file;
    }
}

#===============================================================================
