#!perl
#===============================================================================
#
# t/08_dir_name.t
#
# DESCRIPTION
#   Test script to check getting information for various directory names.
#
# COPYRIGHT
#   Copyright (C) 2003-2006, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use File::Spec::Functions qw(curdir rel2abs splitpath);
use Test::More tests => 22;

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
    my $dir   = rel2abs(curdir());
    my $drive = (splitpath($dir))[0];

    my(@stats, $errno, $lasterror);

    # NOTE: We deliberately call each function in array context, rather than in
    # scalar context to exercise all the features of each function.  (Some code
    # is skipped when they are called in scalar context.)

    $drive =~ s/[\\\/]$//o;
    @stats = Win32::UTCFileTime::stat $drive;
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "stat() works on 'drive:'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::lstat $drive;
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "lstat() works on 'drive:'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::alt_stat($drive);
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "alt_stat() works on 'drive:'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    @stats = Win32::UTCFileTime::stat "$drive.";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "stat() works on 'drive:.'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::lstat "$drive.";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "lstat() works on 'drive:.'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::alt_stat("$drive.");
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "alt_stat() works on 'drive:.'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    @stats = Win32::UTCFileTime::stat "$drive\\";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "stat() works on 'drive:\\'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::lstat "$drive\\";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "lstat() works on 'drive:\\'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::alt_stat("$drive\\");
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "alt_stat() works on 'drive:\\'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    @stats = Win32::UTCFileTime::stat "$drive/";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "stat() works on 'drive:/'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::lstat "$drive/";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "lstat() works on 'drive:/'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::alt_stat("$drive/");
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "alt_stat() works on 'drive:/'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    $dir =~ s/[\\\/]$//o;
    @stats = Win32::UTCFileTime::stat $dir;
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "stat() works on 'dir'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::lstat $dir;
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "lstat() works on 'dir'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::alt_stat($dir);
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "alt_stat() works on 'dir'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    @stats = Win32::UTCFileTime::stat "$dir\\";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "stat() works on 'dir\\'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::lstat "$dir\\";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "lstat() works on 'dir\\'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::alt_stat("$dir\\");
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "alt_stat() works on 'dir\\'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    @stats = Win32::UTCFileTime::stat "$dir/";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "stat() works on 'dir/'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::lstat "$dir/";
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "lstat() works on 'dir/'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    @stats = Win32::UTCFileTime::alt_stat("$dir/");
    ($errno, $lasterror) = ($!, $^E);
    ok(scalar @stats, "alt_stat() works on 'dir/'") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
}

#===============================================================================
