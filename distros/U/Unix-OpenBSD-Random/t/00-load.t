#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Unix::OpenBSD::Random') || print "Bail out!\n";
}

diag(
    "Testing Unix::OpenBSD::Random $Unix::OpenBSD::Random::VERSION, Perl $], $^X");
