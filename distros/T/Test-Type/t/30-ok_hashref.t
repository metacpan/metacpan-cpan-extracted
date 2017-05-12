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
	'ok_hashref',
);

{
	test_out( 'ok 1 - Variable is a hashref (allow empty, allow blessed).' );

	ok_hashref(
		{ key => 1 }
	);

	test_test(
		name     => "Test without arguments.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a hashref (allow empty, allow blessed).' );

	ok_hashref(
		[]
	);

	test_test(
		name     => "Test a variable that is not a hashref.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Test variable is a hashref (allow empty, allow blessed).' );

	ok_hashref(
		{ key => 1 },
		name => 'Test variable',
	);

	test_test(
		name     => "Test specifying the variable name.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a hashref (non-empty, allow blessed).' );

	ok_hashref(
		{},
		allow_empty => 0,
	);

	test_test(
		name     => "Test with allow_empty=0.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is a hashref (allow empty, allow blessed).' );

	ok_hashref(
		{},
		allow_empty => 1,
	);

	test_test(
		name     => "Test with allow_empty=1.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is a hashref (allow empty, allow blessed).' );

	ok_hashref(
		bless( {}, 'TestBlessing' ),
		no_blessing => 0,
	);

	test_test(
		name     => "Test with no_blessing=0.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is a hashref (allow empty, no blessing).' );

	ok_hashref(
		bless( {}, 'TestBlessing' ),
		no_blessing => 1,
	);

	test_test(
		name     => "Test with no_blessing=1.",
		skip_err => 1,
	);
}
