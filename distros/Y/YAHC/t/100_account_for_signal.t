#!/usr/bin/env perl

use strict;
use warnings;

use YAHC;
use Test::More;
use Time::HiRes qw/time/;

my ($yahc, $yahc_storage) = YAHC->new({
    account_for_signals => 1
});

my $alrm = 2;
my $timeout = 3;

my $timer_called = 0;
$yahc->loop->now_update();
my $w = $yahc->loop->timer($timeout, 0, sub {
    $timer_called = 1;
    $yahc->break('break because of timeout');
});

my $sigalrm_called = 0;
$SIG{ALRM} = sub {
    $sigalrm_called = 1;
    $yahc->break('break becuase of SIGALRM');
};

alarm($alrm);

my $start = time;
$yahc->run;
my $elapsed = time - $start;

ok($sigalrm_called == 1, 'SIGALRM handler has been called');
ok($timer_called == 0, 'timer handler has not been called');
cmp_ok($elapsed, '>=', $alrm, "SIGALRM was called at >= $alrm seconds");
cmp_ok($elapsed, '<', $timeout, "SIGALRM was called at < $timeout seconds");

done_testing;
