#!perl
#===============================================================================
#
# t/12_errstr.t
#
# DESCRIPTION
#   Test script to check $ErrStr variable.
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

use Test::More tests => 9;

sub new_filename();

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    my $i = 0;
    sub new_filename() {
        $i++;
        return "test$i.txt";
    }

    use_ok('Win32::UTCFileTime', qw(:DEFAULT $ErrStr));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my($file, $fh);

    {
        $file = new_filename();

        open $fh, ">$file";
        close $fh;

        stat $file;
        is($ErrStr, '', '$ErrStr is blank when stat() succeeds');

        unlink $file;

        stat $file;
        like($ErrStr, qr/^Can't stat file '\Q$file\E'/o,
             '$ErrStr is set correctly when stat() fails');
    }

    {
        $file = new_filename();

        open $fh, ">$file";
        close $fh;

        lstat $file;
        is($ErrStr, '', '$ErrStr is blank when lstat() succeeds');

        unlink $file;

        lstat $file;
        like($ErrStr, qr/^Can't stat link '\Q$file\E'/o,
             '$ErrStr is set correctly when lstat() fails');
    }

    {
        $file = new_filename();

        open $fh, ">$file";
        close $fh;

        Win32::UTCFileTime::alt_stat($file);
        is($ErrStr, '', '$ErrStr is blank when alt_stat() succeeds');

        unlink $file;

        Win32::UTCFileTime::alt_stat($file);
        like($ErrStr, qr/^Can't open file '\Q$file\E' for reading/o,
             '$ErrStr is set correctly when alt_stat() fails');
    }

    {
        $file = new_filename();

        open $fh, ">$file";
        close $fh;

        utime undef, undef, $file;
        is($ErrStr, '', '$ErrStr is blank when utime() succeeds');

        unlink $file;

        utime undef, undef, $file;
        like($ErrStr, qr/^Can't open file '\Q$file\E' for updating/o,
             '$ErrStr is set correctly when utime() fails');
    }
}

#===============================================================================
