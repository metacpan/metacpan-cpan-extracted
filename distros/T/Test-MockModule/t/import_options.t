use warnings;
use strict;

use Test::More;
use Test::Warnings qw(warning warnings);

use Test::MockModule;

# Unknown import options should carp (line 30 in import())
{
	my $w = warning { Test::MockModule->import('not_a_real_option') };
	like("$w", qr/Test::MockModule unknown import option 'not_a_real_option'/,
		'unknown import option triggers carp');
}

# Multiple bad options each carp
{
	my @w = warnings { Test::MockModule->import('bogus1', 'bogus2') };
	is(scalar @w, 2, 'two unknown options produce two warnings');
	like("$w[0]", qr/unknown import option 'bogus1'/, 'first warning names first option');
	like("$w[1]", qr/unknown import option 'bogus2'/, 'second warning names second option');
}

# Mixing valid + invalid: valid still applies, invalid still warns
{
	my @w = warnings { Test::MockModule->import('strict', 'huh') };
	is(scalar @w, 1, 'valid option does not warn, only invalid one does');
	like("$w[0]", qr/unknown import option 'huh'/, 'invalid option in mixed list still warns');
}

done_testing();
