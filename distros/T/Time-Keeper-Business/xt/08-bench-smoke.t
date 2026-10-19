#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Author test: every bench script runs, briefly, and prints a PASS or FAIL
# line, so a broken bench is caught here and not on release day.

my @scripts = sort glob('bench/[0-9][0-9]-*.pl');
plan tests => scalar @scripts;
local $ENV{TK_BENCH_SECONDS} = 0.1;
local $ENV{TK_BENCH_RUNS} = 1;
local $ENV{TK_BENCH_LOADS} = 3;
local $ENV{TK_BENCH_SCHEDULES} = 20;
for my $s (@scripts) {
    my $out = `"$^X" -Mblib $s 2>&1`;
    like($out, qr/^(PASS|FAIL) /m, "$s prints a mark line") or diag $out;
}
