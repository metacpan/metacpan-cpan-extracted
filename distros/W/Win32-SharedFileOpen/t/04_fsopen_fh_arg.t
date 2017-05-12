#!perl
#===============================================================================
#
# t/04_fsopen_fh_arg.t
#
# DESCRIPTION
#   Test script to check fsopen()s filehandle argument.
#
# COPYRIGHT
#   Copyright (C) 2002, 2004-2006, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use FileHandle qw();
use IO::File qw();
use IO::Handle qw();
use Symbol qw(gensym);
use Test::More tests => 14;

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
    my $file = 'test.txt';
    my $err = qr/^fsopen\(\) can't use the undefined value/o;

    my($fh, $ret, $errno, $lasterror);
    local *FH;

    eval {
        undef $fh;
        fsopen($fh, $file, 'w', SH_DENYNO);
    };
    like($@, $err, 'undefined scalar');

    eval {
        fsopen(*FH{IO}, $file, 'w', SH_DENYNO);
    };
    like($@, $err, 'uninitialized IO member');

    $ret = fsopen(FH, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'filehandle')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $ret = fsopen('FH', $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'string')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $ret = fsopen(*FH, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'named typeglob')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = gensym();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'anonymous typeglob from gensym()')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = do { local *FH };
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'anonymous typeglob from first-class filehandle')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = new_fh();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'anonymous typeglob from new_fh()')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $ret = fsopen(\*FH, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'typeglob reference')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $ret = fsopen(*FH{IO}, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'initialized IO member')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = IO::Handle->new();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'IO::Handle object')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = IO::File->new();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'IO::File object')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = FileHandle->new();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'FileHandle object')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    unlink $file;
}

#===============================================================================
