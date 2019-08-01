#!/usr/bin/env perl
use 5.012;
use lib 't';
use MyTest;

die "usage: $0 <test name>" unless @ARGV;

Test::Catch::run(@ARGV);

done_testing();
