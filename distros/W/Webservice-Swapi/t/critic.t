use strict;
use warnings;

use Test::More;
use Test::Perl::Critic;

if ( not $ENV{TEST_CRITIC} ) {
	my $msg = 'export TEST_CRITIC=1 to enable code critic.';
	plan( skip_all => $msg );
}

Test::Perl::Critic->import(-profile => "t/perlcritic.rc");
all_critic_ok();
