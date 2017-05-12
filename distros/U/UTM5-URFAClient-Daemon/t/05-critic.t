use strict;
use warnings;

use Test::More;

unless($ENV{RELEASE_TESTING}) {
    plan skip_all => 'Author tests not required for installation';
}

eval 'use Test::Perl::Critic';
plan skip_all => 'Module Test::Perl::Critic required for PBP test' if $@;

all_critic_ok('lib');

