#!/usr/bin/perl

use strict;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/..","$FindBin::Bin/../lib";

my $dist = shift @INC;
$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';
eval { require Test::Fixme;Test::Fixme->import() };
plan( skip_all => 'Test::Fixme not installed; skipping' ) if $@;
run_tests(
	where    => $INC[0],
	match    => qr/\b(?:TODO|FIXME)\b/, # what to check for
	skip_all => $ENV{SKIP},
);
