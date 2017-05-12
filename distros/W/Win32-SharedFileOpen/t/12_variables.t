#!perl
#===============================================================================
#
# t/12_variables.t
#
# DESCRIPTION
#   Test script to check $ErrStr, $Trace and retry variables.
#
# COPYRIGHT
#   Copyright (C) 2002-2006, 2014 Steve Hay.  All rights reserved.
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
use Test::More tests => 45;
use Time::HiRes qw(time);

sub new_filename();
sub stderr(;$);

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    my $i = 0;
    sub new_filename() {
        $i++;
        return "test$i.txt";
    }

    my $stderr;
    sub stderr(;$) {
        if (@_) {
            my $msg = shift;
            if (defined $msg and defined $stderr) {
                $stderr .= $msg;
            }
            else {
                $stderr  = $msg;
            }
        }

        return $stderr;
    }

    use_ok('Win32::SharedFileOpen', qw(:DEFAULT :retry $ErrStr new_fh));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $err  = qr/^Invalid value for '(.*?)': '(.*?)' is not a natural number/o;
    my $tol = 0.02; # Resolution is often around 1ms-15ms, so allow 20ms.

    my($file, $fh1, $fh2, $output, $ret, $start, $finish, $time, $max_time);

    local $SIG{__WARN__} = \&stderr;

    {
        $file = new_filename();
        $fh1 = new_fh();
        fsopen($fh1, $file, 'w+', SH_DENYNO);
        close $fh1;
        is($ErrStr, '', '$ErrStr is blank when fsopen() succeeds');
        unlink $file;
    }

    {
        $file = new_filename();

        $fh1 = new_fh();
        fsopen($fh1, $file, 'r', SH_DENYNO);
        like($ErrStr, qr/^Can't open C file object handle for file '\Q$file\E'/o,
             '$ErrStr is set correctly when fsopen() fails');

        $fh1 = new_fh();
        sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
        close $fh1;
        is($ErrStr, '', '$ErrStr is blank when sopen() succeeds');

        unlink $file;
    }

    {
        $file = new_filename();

        $fh1 = new_fh();
        sopen($fh1, $file, O_RDONLY, SH_DENYNO);
        like($ErrStr, qr/^Can't open C file object handle for file '\Q$file\E'/o,
             '$ErrStr is set correctly when sopen() fails');

        stderr(undef);
        $fh1 = new_fh();
        fsopen($fh1, $file, 'w+', SH_DENYNO);
        close $fh1;
        $output = stderr();
        is($output, undef, '$Trace output for fsopen() is blank when $Trace is 0');

        $Win32::SharedFileOpen::Trace = 1;

        stderr(undef);
        $fh1 = new_fh();
        fsopen($fh1, $file, 'w+', SH_DENYNO);
        close $fh1;
        $output = stderr();
        like($output, qr/_fsopen\(\) on '\Q$file\E' succeeded/o,
             '$Trace output for fsopen() is correct when $Trace is 1');

        $Win32::SharedFileOpen::Trace = 0;

        stderr(undef);
        $fh1 = new_fh();
        sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
        close $fh1;
        $output = stderr();
        is($output, undef, '$Trace output for sopen() is blank when $Trace is 0');

        $Win32::SharedFileOpen::Trace = 1;

        stderr(undef);
        $fh1 = new_fh();
        sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
        close $fh1;
        $output = stderr();
        like($output, qr/_sopen\(\) on '\Q$file\E' succeeded/o,
             '$Trace output for sopen() is correct when $Trace is 1');

        $Win32::SharedFileOpen::Trace = 0;

        unlink $file;
    }

    {
        eval { $Max_Time = ''; };
        ok($@ =~ $err && $1 eq '$Max_Time' && $2 eq '',
           '$Max_Time can\'t be set to the null string') or
           diag("\$@ = '$@'");

        eval { $Max_Time = 'a'; };
        ok($@ =~ $err && $1 eq '$Max_Time' && $2 eq 'a',
           '$Max_Time can\'t be set to \'a\'') or
           diag("\$@ = '$@'");

        eval { $Max_Time = -1; };
        ok($@ =~ $err && $1 eq '$Max_Time' && $2 eq '-1',
           '$Max_Time can\'t be set to -1') or
           diag("\$@ = '$@'");

        eval { $Max_Time = 0.5; };
        ok($@ =~ $err && $1 eq '$Max_Time' && $2 eq '0.5',
           '$Max_Time can\'t be set to 0.5') or
           diag("\$@ = '$@'");

        eval { $Max_Time = undef; };
        is($@, '', '$Max_Time can be set to the undefined value');

        eval { $Max_Time = 0; };
        is($@, '', '$Max_Time can be set to 0');

        eval { $Max_Time = 1; };
        is($@, '', '$Max_Time can be set to 1');

        eval { $Max_Time = INFINITE; };
        is($@, '', '$Max_Time can be set to INFINITE');

        $Max_Time = 1;

        $file = new_filename();

        $fh1 = new_fh();
        fsopen($fh1, $file, 'w+', SH_DENYRD);

        $fh2 = new_fh();
        $start = time;
        $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
        $finish = time;
        $time = $finish - $start;
        ok($time > $Max_Time - $tol && $time < $Max_Time + $Retry_Timeout + $tol,
           'fsopen() tried for 1 second with $Max_Time == 1') or
           diag("\$time = '$time'");

        $Max_Time = 3;

        $fh2 = new_fh();
        $start = time;
        $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
        $finish = time;
        $time = $finish - $start;
        ok($time > $Max_Time - $tol && $time < $Max_Time + $Retry_Timeout + $tol,
           'fsopen() tried for 3 seconds with $Max_Time == 3') or
           diag("\$time = '$time'");

        close $fh1;

        $Max_Time = 1;

        $fh1 = new_fh();
        sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

        $fh2 = new_fh();
        $start = time;
        $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
        $finish = time;
        $time = $finish - $start;
        ok($time > $Max_Time - $tol && $time < $Max_Time + $Retry_Timeout + $tol,
           'sopen() tried for 1 second with $Max_Time == 1') or
           diag("\$time = '$time'");

        $Max_Time = 3;

        $fh2 = new_fh();
        $start = time;
        $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
        $finish = time;
        $time = $finish - $start;
        ok($time > $Max_Time - $tol && $time < $Max_Time + $Retry_Timeout + $tol,
           'sopen() tried for 3 seconds with $Max_Time == 3') or
           diag("\$time = '$time'");

        close $fh1;

        $Max_Time = undef;

        unlink $file;
    }

    {
        eval { $Max_Tries = ''; };
        ok($@ =~ $err && $1 eq '$Max_Tries' && $2 eq '',
           '$Max_Tries can\'t be set to the null string') or
           diag("\$@ = '$@'");

        eval { $Max_Tries = 'a'; };
        ok($@ =~ $err && $1 eq '$Max_Tries' && $2 eq 'a',
           '$Max_Tries can\'t be set to \'a\'') or
           diag("\$@ = '$@'");

        eval { $Max_Tries = -1; };
        ok($@ =~ $err && $1 eq '$Max_Tries' && $2 eq '-1',
           '$Max_Tries can\'t be set to -1') or
           diag("\$@ = '$@'");

        eval { $Max_Tries = 0.5; };
        ok($@ =~ $err && $1 eq '$Max_Tries' && $2 eq '0.5',
           '$Max_Tries can\'t be set to 0.5') or
           diag("\$@ = '$@'");

        eval { $Max_Tries = undef; };
        is($@, '', '$Max_Tries can be set to the undefined value');

        eval { $Max_Tries = 0; };
        is($@, '', '$Max_Tries can be set to 0');

        eval { $Max_Tries = 1; };
        is($@, '', '$Max_Tries can be set to 1');

        eval { $Max_Tries = INFINITE; };
        is($@, '', '$Max_Tries can be set to INFINITE');

        $Win32::SharedFileOpen::Trace = 1;
        $Max_Tries = 1;

        $file = new_filename();

        $fh1 = new_fh();
        fsopen($fh1, $file, 'w+', SH_DENYRD);

        stderr(undef);
        $fh2 = new_fh();
        $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
        $output = stderr();
        like($output, qr/after 1 try/o,
           'fsopen() tried 1 time with $Max_Tries == 1');

        $Max_Tries = 10;

        stderr(undef);
        $fh2 = new_fh();
        $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
        $output = stderr();
        like($output, qr/after 10 tries/o,
           'fsopen() tried 10 times with $Max_Tries == 10');

        close $fh1;

        $Max_Tries = 1;

        $fh1 = new_fh();
        sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

        stderr(undef);
        $fh2 = new_fh();
        $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
        $output = stderr();
        like($output, qr/after 1 try/o,
           'sopen() tried 1 time with $Max_Tries == 1');

        $Max_Tries = 10;

        stderr(undef);
        $fh2 = new_fh();
        $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
        $output = stderr();
        like($output, qr/after 10 tries/o,
           'sopen() tried 10 times with $Max_Tries == 10');

        close $fh1;

        $Max_Tries = undef;
        $Win32::SharedFileOpen::Trace = 0;

        unlink $file;
    }

    {
        eval { $Retry_Timeout = ''; };
        ok($@ =~ $err && $1 eq '$Retry_Timeout' && $2 eq '',
           '$Retry_Timeout can\'t be set to the null string') or
           diag("\$@ = '$@'");

        eval { $Retry_Timeout = 'a'; };
        ok($@ =~ $err && $1 eq '$Retry_Timeout' && $2 eq 'a',
           '$Retry_Timeout can\'t be set to \'a\'') or
           diag("\$@ = '$@'");

        eval { $Retry_Timeout = -1; };
        ok($@ =~ $err && $1 eq '$Retry_Timeout' && $2 eq '-1',
           '$Retry_Timeout can\'t be set to -1') or
           diag("\$@ = '$@'");

        eval { $Retry_Timeout = 0.5; };
        ok($@ =~ $err && $1 eq '$Retry_Timeout' && $2 eq '0.5',
           '$Retry_Timeout can\'t be set to 0.5') or
           diag("\$@ = '$@'");

        eval { $Retry_Timeout = undef; };
        is($@, '', '$Retry_Timeout can be set to the undefined value');

        eval { $Retry_Timeout = 0; };
        is($@, '', '$Retry_Timeout can be set to 0');

        eval { $Retry_Timeout = 1; };
        is($@, '', '$Retry_Timeout can be set to 1');

        eval { $Retry_Timeout = INFINITE; };
        is($@, '', '$Retry_Timeout can be set to INFINITE');

        $Max_Tries = 5;
        $Retry_Timeout = 250;
        $max_time = ($Max_Tries - 1) * $Retry_Timeout / 1000;

        $file = new_filename();

        $fh1 = new_fh();
        fsopen($fh1, $file, 'w+', SH_DENYRD);

        $fh2 = new_fh();
        $start = time;
        $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
        $finish = time;
        $time = $finish - $start;
        ok($time > $max_time - $tol && $time < $max_time + $tol,
           'fsopen() tried for 1 second with $Retry_Timeout == 250') or
           diag("\$time = '$time'");

        $Retry_Timeout = 750;
        $max_time = ($Max_Tries - 1) * $Retry_Timeout / 1000;

        $fh2 = new_fh();
        $start = time;
        $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
        $finish = time;
        $time = $finish - $start;
        ok($time > $max_time - $tol && $time < $max_time + $tol,
           'fsopen() tried for 3 seconds with $Retry_Timeout == 750') or
           diag("\$time = '$time'");

        close $fh1;

        $Retry_Timeout = 250;
        $max_time = ($Max_Tries - 1) * $Retry_Timeout / 1000;

        $fh1 = new_fh();
        sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

        $fh2 = new_fh();
        $start = time;
        $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
        $finish = time;
        $time = $finish - $start;
        ok($time > $max_time - $tol && $time < $max_time + $tol,
           'sopen() tried for 1 second with $Retry_Timeout == 250') or
           diag("\$time = '$time'");

        $Retry_Timeout = 750;
        $max_time = ($Max_Tries - 1) * $Retry_Timeout / 1000;

        $fh2 = new_fh();
        $start = time;
        $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
        $finish = time;
        $time = $finish - $start;
        ok($time > $max_time - $tol && $time < $max_time + $tol,
           'sopen() tried for 3 seconds with $Retry_Timeout == 750') or
           diag("\$time = '$time'");

        close $fh1;

        $Retry_Timeout = 250;
        $Max_Tries = undef;

        unlink $file;
    }
}

#===============================================================================
