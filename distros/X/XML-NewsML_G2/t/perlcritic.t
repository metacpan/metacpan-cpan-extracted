#!/usr/bin/env perl

use File::Spec;
use Test::More;

use warnings;
use strict;

if (not $ENV{RELEASE_TESTING}) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan(skip_all => $msg);
}

eval {require Test::Perl::Critic; } or do {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan(skip_all => $msg);
};

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
