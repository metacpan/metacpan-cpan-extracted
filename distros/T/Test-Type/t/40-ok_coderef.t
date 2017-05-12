#!perl -T

use strict;
use warnings;

use Data::Validate::Type;
use Test::Builder::Tester;
use Test::FailWarnings;
use Test::More tests => 4;
use Test::Type;


can_ok(
	'Test::Type',
	'ok_coderef',
);

{
	test_out( 'ok 1 - Variable is a coderef.' );

	ok_coderef(
		sub
		{
			return 0;
		},
	);

	test_test(
		name     => "Test without arguments.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a coderef.' );

	ok_coderef(
		[]
	);

	test_test(
		name     => "Test a variable that is not a coderef.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Test subroutine is a coderef.' );

	ok_coderef(
		sub
		{
			return 0;
		},
		name => 'Test subroutine',
	);

	test_test(
		name     => "Test specifying the variable name.",
		skip_err => 1,
	);
}
