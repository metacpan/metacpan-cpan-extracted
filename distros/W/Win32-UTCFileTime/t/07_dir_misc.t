#!perl
#===============================================================================
#
# t/07_dir_misc.t
#
# DESCRIPTION
#   Test script to check getting miscellaneous directory information.
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

use Test::More tests => 28;

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
    my $dir = 'test';

    my(@cstats, @rstats, @astats);

    mkdir $dir or die "Can't create directory '$dir': $!\n";

    @cstats = CORE::stat $dir;
    @rstats = Win32::UTCFileTime::stat $dir;
    @astats = Win32::UTCFileTime::alt_stat($dir);

    is($rstats[0], $cstats[0], "stat() gets 'dev' field OK");
    is($astats[0], $cstats[0], "alt_stat() gets 'dev' field OK");

    is($rstats[1], $cstats[1], "stat() gets 'ino' field OK");
    is($astats[1], $cstats[1], "alt_stat() gets 'ino' field OK");

    is($rstats[3], $cstats[3], "stat() gets 'nlink' field OK");
    is($astats[3], $cstats[3], "alt_stat() gets 'nlink' field OK");

    is($rstats[4], $cstats[4], "stat() gets 'uid' field OK");
    is($astats[4], $cstats[4], "alt_stat() gets 'uid' field OK");

    is($rstats[5], $cstats[5], "stat() gets 'gid' field OK");
    is($astats[5], $cstats[5], "alt_stat() gets 'gid' field OK");

    is($rstats[6], $cstats[6], "stat() gets 'rdev' field OK");
    is($astats[6], $cstats[6], "alt_stat() gets 'rdev' field OK");

    is($rstats[7], $cstats[7], "stat() gets 'size' field OK");
    is($astats[7], $cstats[7], "alt_stat() gets 'size' field OK");

    is($rstats[11], $cstats[11], "stat() gets 'blksize' field OK");
    is($astats[11], $cstats[11], "alt_stat() gets 'blksize' field OK");

    is($rstats[12], $cstats[12], "stat() gets 'blocks' field OK");
    is($astats[12], $cstats[12], "alt_stat() gets 'blocks' field OK");

    @cstats = CORE::lstat $dir;
    @rstats = Win32::UTCFileTime::lstat $dir;

    is($rstats[0], $cstats[0], "lstat() gets 'dev' field OK");

    is($rstats[1], $cstats[1], "lstat() gets 'ino' field OK");

    is($rstats[3], $cstats[3], "lstat() gets 'nlink' field OK");

    is($rstats[4], $cstats[4], "lstat() gets 'uid' field OK");

    is($rstats[5], $cstats[5], "lstat() gets 'gid' field OK");

    is($rstats[6], $cstats[6], "lstat() gets 'rdev' field OK");

    is($rstats[7], $cstats[7], "lstat() gets 'size' field OK");

    is($rstats[11], $cstats[11], "lstat() gets 'blksize' field OK");

    is($rstats[12], $cstats[12], "lstat() gets 'blocks' field OK");

    rmdir $dir;
}

#===============================================================================
