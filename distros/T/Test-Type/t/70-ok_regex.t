#!perl -T

use strict;
use warnings;

use Test::Builder::Tester;
use Test::FailWarnings;
use Test::More tests => 4;
use Test::Type;


can_ok(
	'Test::Type',
	'ok_regex',
);

{
	test_out( 'not ok 1 - Variable is a regular expression.' );

	ok_regex(
		'test'
	);

	test_test(
		name     => "Test with a string.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is a regular expression.' );

	ok_regex(
		qr/test/,
	);

	test_test(
		name     => "Test with a regular expression.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Variable is a regular expression.' );

	ok_regex(
		qr//,
	);

	test_test(
		name     => "Test with an empty regular expression.",
		skip_err => 1,
	);
}
