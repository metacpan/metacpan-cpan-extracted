#!perl -T

use strict;
use warnings;

use Data::Validate::Type;
use Test::Builder::Tester;
use Test::FailWarnings;
use Test::More tests => 9;
use Test::Type;


can_ok(
	'Test::Type',
	'ok_arrayref',
);

{
	test_out( 'ok 1 - Variable is an arrayref (allow empty, allow blessed).' );

	ok_arrayref(
		[ 1, 2, 3 ]
	);

	test_test(
		name     => "Test without arguments.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is an arrayref (allow empty, allow blessed).' );

	ok_arrayref(
		{ }
	);

	test_test(
		name     => "Test a variable that is not an arrayref.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Test variable is an arrayref (allow empty, allow blessed).' );

	ok_arrayref(
		[ 1, 2, 3 ],
		name => 'Test variable',
	);

	test_test(
		name     => "Test specifying the variable name.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is an arrayref (non-empty, allow blessed).' );

	ok_arrayref(
		[],
		allow_empty => 0,
	);

	test_test(
		name     => "Test with allow_empty=0.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is an arrayref (allow empty, allow blessed).' );

	ok_arrayref(
		[],
		allow_empty => 1,
	);

	test_test(
		name     => "Test with allow_empty=1.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is an arrayref (allow empty, allow blessed).' );

	ok_arrayref(
		bless( [], 'TestBlessing' ),
		no_blessing => 0,
	);

	test_test(
		name     => "Test with no_blessing=0.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is an arrayref (allow empty, no blessing).' );

	ok_arrayref(
		bless( [], 'TestBlessing' ),
		no_blessing => 1,
	);

	test_test(
		name     => "Test with no_blessing=1.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is an arrayref (allow empty, allow blessed, validate elements).' );

	ok_arrayref(
		[
			{},
			'',
		],
		element_validate_type =>
			sub
			{
				return Data::Validate::Type::is_hashref( $_[0] );
			},
	);

	test_test(
		name     => "Test with element_validate_type set to validate hashrefs.",
		skip_err => 1,
	);
}
