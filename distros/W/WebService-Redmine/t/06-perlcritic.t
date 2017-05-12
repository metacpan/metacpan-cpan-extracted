BEGIN {
	use strict;
	use warnings;
	if (!$ENV{REDMINER_DEVEL}) {
		require Test::More;
		Test::More::plan(skip_all => 'Development tests (REDMINER_DEVEL not set)' );
	}
};

eval 'use Test::Perl::Critic';

plan(skip_all => 'Test::Perl::Critic required to criticise code') if $@;

Test::Perl::Critic->import(-profile => 'xt/perlcritic.rc') if -e 'xt/perlcritic.rc';

all_critic_ok();
