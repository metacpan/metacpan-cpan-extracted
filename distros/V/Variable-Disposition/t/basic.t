use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Variable::Disposition;

{
	my $x = [1,2,3];
	isa_ok($x, 'ARRAY');
	dispose $x;
	is($x, undef, 'was undefined correctly');
}

{
	my $x = [1,2,3];
	my $copy = $x;
	like(exception {
		dispose $x;
	}, qr/not released/, 'raise an exception if variable is still around');
	is($x, undef, 'was still undefined correctly');
	is(exception {
		dispose $copy;
	}, undef, 'no exception when last copy goes');
}

{
	my $x = 'test';
	like(exception {
		dispose $x;
	}, qr/not a ref/, 'raise an exception when called on non-ref');
	is($x, 'test', 'still defined');
	undef $x;
	like(exception {
		dispose $x;
	}, qr/not defined/, 'raise an exception when called on undef');
}

my $destroyed = 0;
{
	{
		package Local::Test;
		sub DESTROY { ++$destroyed }
	}
	my $x = bless {}, 'Local::Test';
	is($destroyed, 0, 'not yet destroyed');
	dispose $x;
	is($destroyed, 1, 'destroyed after dispose()');
	is($x, undef, 'was undef');
}
is($destroyed, 1, 'still only a single DESTROY called when leaving scope');

done_testing;

