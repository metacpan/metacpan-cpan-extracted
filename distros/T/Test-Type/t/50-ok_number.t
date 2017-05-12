#!perl -T

use strict;
use warnings;

use Data::Validate::Type;
use Test::Builder::Tester;
use Test::FailWarnings;
use Test::More tests => 8;
use Test::Type;


can_ok(
	'Test::Type',
	'ok_number',
);

{
	test_out( 'ok 1 - Variable is a number.' );

	ok_number(
		1
	);

	test_test(
		name     => "Test without arguments.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a number.' );

	ok_number(
		[]
	);

	test_test(
		name     => "Test a variable that is not a number.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Test variable is a number.' );

	ok_number(
		1,
		name => 'Test variable',
	);

	test_test(
		name     => "Test specifying the variable name.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is a number.' );

	ok_number(
		-1,
		positive => 0,
	);

	test_test(
		name     => "Test with positive=0.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a number (positive).' );

	ok_number(
		-1,
		positive => 1,
	);

	test_test(
		name     => "Test with positive=1.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is a number.' );

	ok_number(
		0,
		strictly_positive => 0,
	);

	test_test(
		name     => "Test with strictly_positive=0.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a number (strictly positive).' );

	ok_number(
		0,
		strictly_positive => 1,
	);

	test_test(
		name     => "Test with strictly_positive=1.",
		skip_err => 1,
	);
}
