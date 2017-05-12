#!perl

use utf8;
use strict;
use warnings;

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

use Test::Perl::Critic (-exclude => ['Subroutines::ProhibitSubroutinePrototypes']);
all_critic_ok();
