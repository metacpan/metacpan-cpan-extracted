#!perl -T
use 5.006;
use strict;
use warnings;

use Test::Perl::Critic (-exclude => ['ProhibitStringyEval']);
use Test::More;

unless ( $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

critic_ok('lib/Test2/Aggregate.pm');

done_testing;
