#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

# we are testing ourselves, so we don't want this warning
BEGIN { $ENV{_KWALITEE_NO_WARN} = 1; }

$TODO = 'local::lib is not compatible with taint mode'
    if $ENV{PERL_LOCAL_LIB_ROOT};

# these tests all pass without building the dist
my @expected = qw(
    has_changelog
    has_readme
    has_tests
);

my $test_count;
subtest 'Test::Kwalitee import' => sub {
    require Test::Kwalitee;
    # we use an eval because Module::CPANTS::Analyse is not yet taint-clean
    eval { Test::Kwalitee->import(tests => \@expected) };
    $test_count = Test::Builder->new->current_test,
};

is(
    $test_count,
    scalar(@expected),
    'ran the expected number of tests',
);

done_testing;
