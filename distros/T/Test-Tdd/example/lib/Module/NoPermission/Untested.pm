package Module::NoPermission::Untested;

use strict;
use warnings;
use Test::Tdd::Generator;


sub untested_subroutine {
	Test::Tdd::Generator::create_test('creates test on tmp');

	return shift;
}

1;