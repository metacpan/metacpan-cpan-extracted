#!/usr/bin/perl

use strict;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/..","$FindBin::Bin/../lib";

my $dist = shift @INC;
# warn "$dist";
$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';
chdir $dist or plan skip_all => "Can't chdir to $dist: $!";
eval { require Test::Kwalitee; Test::Kwalitee->import(basedir => $dist) };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

END {
	-e 'Debian_CPANTS.txt' and do { unlink 'Debian_CPANTS.txt' or $! and warn $! };
}
