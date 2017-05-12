#!perl -T

use strict;
use warnings;

use Test::Builder::Tester;
use Test::FailWarnings;
use Test::More tests => 6;
use Test::Type;


can_ok(
	'Test::Type',
	'ok_string',
);

{
	test_out( 'ok 1 - Variable is a string (allow empty).' );

	ok_string(
		'test'
	);

	test_test(
		name     => "Test without arguments.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a string (allow empty).' );

	ok_string(
		{}
	);

	test_test(
		name     => "Test with a variable that is not a string.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Test variable is a string (allow empty).' );

	ok_string(
		'test',
		'name' => 'Test variable',
	);

	test_test(
		name     => "Test specifying the variable name.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is a string (allow empty).' );

	ok_string(
		'',
		allow_empty => 1,
	);

	test_test(
		name     => "Test with allow_empty=1.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a string (non-empty).' );

	ok_string(
		'',
		allow_empty => 0,
	);

	test_test(
		name     => "Test with allow_empty=0.",
		skip_err => 1,
	);
}
