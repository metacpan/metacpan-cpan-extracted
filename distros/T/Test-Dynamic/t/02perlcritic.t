#!/usr/bin/perl -- -*-cperl-*-

use strict;
use warnings;
use Test::More;

if (! $ENV{TEST_AUTHOR}) {
	plan (skip_all =>  'Must set $ENV{TEST_AUTHOR} to run Perl::Critic tests');
}

eval {
	require Perl::Critic;
};
if ($@) {
   plan (skip_all =>  'Perl::Critic needed to run this test');
}
eval {
	require Test::Perl::Critic;
};
if ($@) {
   plan (skip_all =>  'Test::Perl::Critic needed to run this test');
}

## Gotta have a profile
my $PROFILE = '.perlcriticrc';
if (! -e $PROFILE) {
	plan (skip_all =>  qq{Perl::Critic profile "$PROFILE" not found\n});
}

## Gotta have our code
my $CODE = './Dynamic.pm';
if (! -e $CODE) {
	plan (skip_all =>  qq{Perl::Critic cannot find "$CODE" to test with\n});
}

plan tests => 1;
Test::Perl::Critic->import( -profile => $PROFILE );
critic_ok($CODE);


