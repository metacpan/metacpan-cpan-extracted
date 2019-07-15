#!/usr/bin/env perl
use 5.012;
use lib 't';
use MyTest;

my $tname = shift(@ARGV) or die "usage: $0 <test name>";

Test::Catch::run($tname);

done_testing();
