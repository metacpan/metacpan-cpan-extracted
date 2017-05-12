#!perl
#===============================================================================
#
# t/09_default_arg.t
#
# DESCRIPTION
#   Test script to check default arguments.
#
# COPYRIGHT
#   Copyright (C) 2004-2006, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Test::More tests => 7;

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
    my $file = 'test.txt';

    my($fh, @stats1, @stats2, $ok);

    open $fh, ">$file" or die "Can't create file '$file': $!\n";
    close $fh;

    @stats1 = Win32::UTCFileTime::stat $file;
    $_ = $file;
    @stats2 = Win32::UTCFileTime::stat;

    is($_, $file, "stat() does not change \$_");
    is_deeply(\@stats2, \@stats1,
       '... and gets the same results as stat($file)');

    @stats1 = Win32::UTCFileTime::lstat $file;
    $_ = $file;
    @stats2 = Win32::UTCFileTime::lstat;

    is($_, $file, "lstat() does not change \$_");
    is_deeply(\@stats2, \@stats1,
       '... and gets the same results as lstat($file)');

    @stats1 = Win32::UTCFileTime::alt_stat($file);
    $_ = $file;
    @stats2 = Win32::UTCFileTime::alt_stat;

    is($_, $file, "alt_stat() does not change \$_");
    is_deeply(\@stats2, \@stats1,
       '... and gets the same results as alt_stat($file)');

    unlink $file;
}

#===============================================================================
