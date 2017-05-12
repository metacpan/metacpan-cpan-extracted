#!/usr/bin/perl

use strict;
use ex::lib qw(.. ../lib);
use Test::More;

my $dist = shift @INC;
eval { require Test::Kwalitee; Test::Kwalitee->import(basedir => $dist) };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

END {
	-e 'Debian_CPANTS.txt' and do { unlink 'Debian_CPANTS.txt' or $! and warn $! };
}
