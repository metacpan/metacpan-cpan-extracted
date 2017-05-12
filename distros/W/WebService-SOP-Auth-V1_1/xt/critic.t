use strict;
use warnings;
use Test::More;

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import;
};
note $@ if $@;
plan skip_all => 'Test::Perl::Critic is not installed' if $@;

all_critic_ok('lib');
