#!perl
#===============================================================================
#
# t/05_sopen_fh_arg.t
#
# DESCRIPTION
#   Test script to check sopen()s filehandle argument.
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
    my $err = qr/^sopen\(\) can't use the undefined value/o;

    my($fh, $ret, $errno, $lasterror);
    local *FH;

    eval {
        undef $fh;
        sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    };
    like($@, $err, 'undefined scalar');

    eval {
        sopen(*FH{IO}, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
              S_IWRITE);
    };
    like($@, $err, 'unitialized IO member');

    $ret = sopen(FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'filehandle')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $ret = sopen('FH', $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
                 S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'string')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $ret = sopen(*FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'named typeglob')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = gensym();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'anonymous typeglob from gensym()')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = do { local *FH };
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'anonymous typeglob from first-class filehandle')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'anonymous typeglob from new_fh()')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $ret = sopen(\*FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
                 S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'typeglob reference')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $ret = sopen(*FH{IO}, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
                 S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'initialized IO member')
        ? close FH : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = IO::Handle->new();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'IO::Handle object')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = IO::File->new();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'IO::File object')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    $fh = FileHandle->new();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'FileHandle object')
        ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");

    unlink $file;
}

#===============================================================================
