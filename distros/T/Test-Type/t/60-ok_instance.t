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
	'ok_instance',
);

{
	test_out( 'ok 1 - Variable is an instance of TestBless.' );

	ok_instance(
		bless(
			{},
			'TestBless',
		),
		class => 'TestBless',
	);

	test_test(
		name     => "Test without arguments.",
		skip_err => 1,
	);
}

{
	test_out( 'not ok 1 - Variable is an instance of TestBless.' );

	ok_instance(
		bless(
			{},
			'TestBless2',
		),
		class => 'TestBless',
	);

	test_test(
		name     => "Test a variable that is not an instance of the specified class.",
		skip_err => 1,
	);
}

{
	test_out( 'ok 1 - Object is an instance of TestBless.' );

	ok_instance(
		bless(
			{},
			'TestBless',
		),
		class => 'TestBless',
		name  => 'Object',
	);

	test_test(
		name     => "Test specifying the variable name.",
		skip_err => 1,
	);
}
