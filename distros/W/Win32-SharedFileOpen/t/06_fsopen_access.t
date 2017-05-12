#!perl
#===============================================================================
#
# t/06_fsopen_access.t
#
# DESCRIPTION
#   Test script to check fsopen() access modes.
#
# COPYRIGHT
#   Copyright (C) 2001-2006, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Config qw(%Config);
use Errno qw(EACCES ENOENT);
use Test::More tests => 52;
use Win32::WinError qw(ERROR_ACCESS_DENIED ERROR_FILE_NOT_FOUND);

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

    use_ok('Win32::SharedFileOpen', qw(:DEFAULT new_fh));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $str    = 'Hello, world.';
    my $strlen = length $str;
    my $bcc    = $Config{cc} =~ /bcc32/io;

    my($file, $fh, $ret, $errno, $lasterror, $line);

    {
        $file = new_filename();

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'r', SH_DENYNO);
        # Borland C++ builds of perl seem to wipe out $^E if $! is accessed first.
        ($lasterror, $errno) = ($^E + 0, $! + 0);
        is($ret, undef, "fsopen() initially fails with 'r'");
        is($errno, ENOENT, '... and sets $! correctly');
        is($lasterror, ERROR_FILE_NOT_FOUND, '... and sets $^E correctly');

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'w', SH_DENYNO);
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, "fsopen() succeeds with 'w'") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        ok(print($fh "$str\n"), '... and we can print');

        seek $fh, 0, 0;
        {
            no warnings 'io';
            is(<$fh>, undef, '... but not read');
        }

        ok(close($fh), '... and the file closes ok');
        is(-s $file, $strlen + 2, '... and the file size is ok');

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'r', SH_DENYNO);
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, "fsopen() now succeeds with 'r'") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        {
            no warnings 'io';
            ok(!print($fh "$str\n"), "... and we cannot print");
        }

        seek $fh, 0, 0;
        chomp($line = <$fh>);
        is($line, $str, '... but we can read');

        ok(close($fh), '... and the file closes ok');
        is(-s $file, $strlen + 2, '... and the file size is still ok');

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'a', SH_DENYNO);
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, "fsopen() succeeds with 'a'") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        ok(print($fh "$str\n"), '... and we can print');

        seek $fh, 0, 0;
        {
            no warnings 'io';
            is(<$fh>, undef, '... but not read');
        }

        ok(close($fh), '... and the file closes ok');
        is(-s $file, ($strlen + 2) * 2, '... and the file size is ok');

        unlink $file;
    }

    {
        $file = new_filename();

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'r+', SH_DENYNO);
        ($lasterror, $errno) = ($^E + 0, $! + 0);
        is($ret, undef, "fsopen() initially fails with 'r+'");
        is($errno, ENOENT, '... and sets $! correctly');
        is($lasterror, ERROR_FILE_NOT_FOUND, '... and sets $^E correctly');

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'w+', SH_DENYNO);
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, "fsopen() succeeds with 'w+'") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        ok(print($fh "$str\n"), '... and we can print');

        seek $fh, 0, 0;
        chomp($line = <$fh>);
        is($line, $str, '... and read');

        ok(close($fh), '... and the file closes ok');
        is(-s $file, $strlen + 2, '... and the file size is ok');

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'r+', SH_DENYNO);
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, "fsopen() now succeeds with 'r+'") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        ok(print($fh "$str\n"), '... and we can print');

        seek $fh, 0, 0;
        chomp($line = <$fh>);
        is($line, $str, '... and read');

        ok(close($fh), '... and the file closes ok');
        is(-s $file, $strlen + 2, '... and the file size is ok');

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'a+', SH_DENYNO);
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, "fsopen() succeeds with 'a+'") or
            diag("\$! = '$errno', \$^E = '$lasterror'");

        ok(print($fh "$str\n"), '... and we can print');

        seek $fh, 0, 0;
        chomp($line = <$fh>);
        is($line, $str, '... and read');

        ok(close($fh), '... and the file closes ok');
        is(-s $file, ($strlen + 2) * 2, '... and the file size is ok');

        unlink $file;
    }

    {
        $file = new_filename();
        $fh = new_fh();
        fsopen($fh, $file, 'wt', SH_DENYNO);
        print $fh "$str\n";
        close $fh;
        is(-s $file, $strlen + 2, "'t' works");
        unlink $file;
    }

    {
        $file = new_filename();
        $fh = new_fh();
        fsopen($fh, $file, 'wt', SH_DENYNO);
        binmode $fh, ':raw';
        print $fh "$str\n";
        close $fh;
        is(-s $file, $strlen + 1, "'t' and a ':raw' layer works");
        unlink $file;
    }

    {
        $file = new_filename();
        $fh = new_fh();
        fsopen($fh, $file, 'wb', SH_DENYNO);
        print $fh "$str\n";
        close $fh;
        is(-s $file, $strlen + 1, "'b' works");
        unlink $file;
    }

    {
        $file = new_filename();
        $fh = new_fh();
        fsopen($fh, $file, 'wb', SH_DENYNO);
        binmode $fh, ':crlf';
        print $fh "$str\n";
        close $fh;
        is(-s $file, $strlen + 2, "'b' and a ':crlf' layer works");
        unlink $file;
    }

    SKIP: {
        skip "Borland C RTL doesn't support 'D'", 1 if $bcc;
        $file = new_filename();
        $fh = new_fh();
        fsopen($fh, $file, "wD", SH_DENYNO);
        print $fh "$str\n";
        close $fh;
        ok(! -e $file, "'D' works");
        unlink $file;
    }

    $fh = new_fh();
    $ret = fsopen($fh, '.', 'r', SH_DENYNO);
    ($lasterror, $errno) = ($^E + 0, $! + 0);
    is($ret, undef, 'fsopen() fails reading a directory');
    is($errno, EACCES, '... and sets $! correctly');
    is($lasterror, ERROR_ACCESS_DENIED, '... and sets $^E correctly');

    $fh = new_fh();
    $ret = fsopen($fh, '.', 'w', SH_DENYNO);
    ($lasterror, $errno) = ($^E + 0, $! + 0);
    is($ret, undef, 'fsopen() fails writing a directory');
    is($errno, EACCES, '... and sets $! correctly');
    is($lasterror, ERROR_ACCESS_DENIED, '... and sets $^E correctly');

    {
        $file = new_filename();

        $fh = new_fh();
        fsopen($fh, $file, 'w', SH_DENYNO);
        print $fh "$str\n";
        close $fh;
        chmod 0444, $file;

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'r', SH_DENYNO);
        ($errno, $lasterror) = ($!, $^E);
        ok($ret, 'fsopen() succeeds reading a read-only file') or
            diag("\$! = '$errno', \$^E = '$lasterror'");
        close $fh;

        $fh = new_fh();
        $ret = fsopen($fh, $file, 'w', SH_DENYNO);
        ($lasterror, $errno) = ($^E + 0, $! + 0);
        is($ret, undef, 'fsopen() fails writing a read-only file');
        is($errno, EACCES, '... and sets $! correctly');
        is($lasterror, ERROR_ACCESS_DENIED, '... and sets $^E correctly');

        chmod 0666, $file;
        unlink $file;
    }
}

#===============================================================================
