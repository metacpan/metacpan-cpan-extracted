#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg =
        'Author test. Set (export) $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval 'use Test::Prereq::Build';

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Prereq::Build not installed; skipping';
    plan( skip_all => $msg );
}
else {
    # workaround, cause this method is missing in Test::Prereq::Build
    no warnings qw(once);
    *Test::Prereq::Build::add_build_element = sub {};
}

# workaround for the bugs of Test::Prereq::Build
my @skip_workaround = qw{
};


# These modules should not go into Build.PL
my @skip_devel_only = qw{
    Test::Kwalitee
    Test::Perl::Critic
    Test::Prereq::Build
};

my @skip = (
    @skip_workaround,
    @skip_devel_only,
);

prereq_ok( undef, undef, \@skip );
