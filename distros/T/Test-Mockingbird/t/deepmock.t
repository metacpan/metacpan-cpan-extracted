#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use Test::Mockingbird;
use Test::Mockingbird::DeepMock qw(deep_mock);

{
	package DMTest;
	sub greet  { "orig" }
	sub double { ($_[1] // 0) * 2 }
};

deep_mock(
	{
		mocks => [
			{
				target => 'DMTest::greet',
				type   => 'mock',
				with   => sub { "mocked" },
			}, {
				target => 'DMTest::double',
				type   => 'spy',
				tag	=> 'double_spy',
			},
		],

		expectations => [
			{
				tag   => 'double_spy',
				calls => 2,
			},
		],
	},
	sub {
		is DMTest::greet(), 'mocked', 'greet() was mocked via DeepMock';

		DMTest::double(2);
		DMTest::double(3);
	}
);

done_testing;
