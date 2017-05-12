use strict;
use warnings;
use Test::More;

#plan skip_all => 'Test::Perl::Critic not enabled' unless $ENV{TEST_PERLCRITIC};
eval q{use Test::Perl::Critic (
	-profile => 't/perlcriticrc',
	-format  => '%p: %m at line %l, column %c.',
)};
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok('lib');
