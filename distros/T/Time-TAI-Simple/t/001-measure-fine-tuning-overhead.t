#!/bin/env perl

use strict;
use warnings;
use Test::Most;
use Time::HiRes;

use lib "./lib";
use Time::TAI::Simple;

my $tm0 = Time::HiRes::time();
for (my $i = 0; $i < 1000; $i++) {
    my $tai_or = Time::TAI::Simple->new(do_not_load_leapseconds => 1);
}
my $with_fine_tuning = (Time::HiRes::time() - $tm0) / 1000;

$tm0 = Time::HiRes::time();
for (my $i = 0; $i < 1000; $i++) {
    my $tai_or = Time::TAI::Simple->new(fine_tune => 0, do_not_load_leapseconds => 1);
}
my $sans_fine_tuning = (Time::HiRes::time() - $tm0) / 1000;

ok 1, "measurements taken";
printf("instantiation time with tuning  %0.08f seconds\n", $with_fine_tuning);
printf("instantiation time sans tuning  %0.08f seconds\n", $sans_fine_tuning);
printf("fine tuning processing overhead %0.08f seconds\n", $with_fine_tuning - $sans_fine_tuning);

done_testing();
exit(0);
