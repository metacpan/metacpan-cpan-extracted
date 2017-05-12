#!/usr/local/bin/perl -w
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, ('../blib/lib', '../blib/arch');
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

use forks::signals;
use Test::More tests => 9;

my $g = '';
my $g_cnt = 0;
my $g_cnt_chk = 0;
my $g_myhup_cnt = 0;
my $g_myhup_cnt_chk = 0;

my $ndef_hup = sub { $g = 'nhup'; $g_cnt++ };
my $def_hup = sub { $g = 'hup'; $g_cnt++ };

import forks::signals
    ifndef  => { HUP => $ndef_hup },
    ifdef   => { HUP => $def_hup };


$SIG{HUP} = undef;
$g_cnt_chk++; kill('SIGHUP', $$);
is( $g,'nhup','Check that not defined HUP signal handler was triggered' );

$SIG{HUP} = 'DEFAULT';
$g_cnt_chk++; kill('SIGHUP', $$);
is( $g,'nhup','Check that not defined HUP signal handler was triggered' );


$SIG{HUP} = 1;
$g_cnt_chk++; kill('SIGHUP', $$);
is( $g,'hup','Check that defined HUP signal handler was triggered' );

$SIG{HUP} = sub { 1 };
$g_cnt_chk++; kill('SIGHUP', $$);
is( $g,'hup','Check that defined HUP signal handler was triggered' );


my $def_myhup = sub { $g = 'myhup'; $g_myhup_cnt++ };

$SIG{HUP} = $def_myhup;
$g_cnt_chk++; $g_myhup_cnt_chk++; kill('SIGHUP', $$);
is( $g,'myhup','Check that defined HUP signal handler was triggered' );

$SIG{HUP} = $def_myhup;
$g_cnt_chk++; $g_myhup_cnt_chk++; kill('SIGHUP', $$);
is( $g,'myhup','Check that defined HUP signal handler was triggered' );

$SIG{HUP} = undef;
$SIG{HUP} = $def_myhup;
$SIG{HUP} = $def_myhup;
$g_cnt_chk++; $g_myhup_cnt_chk++; kill('SIGHUP', $$);
is( $g,'myhup','Check that defined HUP signal handler was triggered' );

$SIG{HUP} = 'IGNORE';
kill('SIGHUP', $$);


is( $g_cnt,$g_cnt_chk,'Check that all expected signals were handled' );
is( $g_myhup_cnt,$g_myhup_cnt_chk,'Verify no internal signal recursion occured' );

1;
