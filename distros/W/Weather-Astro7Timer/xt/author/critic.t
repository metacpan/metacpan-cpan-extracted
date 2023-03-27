#!perl -T
use 5.006;
use strict;
use warnings;

use Test::Perl::Critic (-exclude => ['ProhibitStringyEval']);
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

critic_ok('lib/Weather/Astro7Timer.pm');

done_testing;
