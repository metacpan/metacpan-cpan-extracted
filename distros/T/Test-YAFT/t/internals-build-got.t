#!/usr/bin/env perl

use v5.14;
use  warnings;

use require::relative "test-helper.pl";

it "should build result from non-coderef"
	=> got    => Test::YAFT::_build_got ({ got => "foo" })
	=> expect => +{
		error    => undef,
		lives_ok => expect_true,
		value    => "foo",
	};

it "should execute coderef"
	=> got    => Test::YAFT::_build_got ({ got => sub { 'foo' } })
	=> expect => +{
		error    => '',
		lives_ok => expect_true,
		value    => "foo",
	};

it "should execute coderef in scalar context"
	=> got    => Test::YAFT::_build_got ({ got => sub { qw[ foo bar ] } })
	=> expect => +{
		error    => '',
		lives_ok => expect_true,
		value    => "bar",
	};

it "should catch exception thrown by coderef"
	=> got    => Test::YAFT::_build_got ({ got => sub { die bless {}, 'Foo::Bar' } })
	=> expect => +{
		error    => expect_isa ('Foo::Bar'),
		lives_ok => expect_false,
		value    => undef,
	};

it "should execute got { } block"
	=> got    => Test::YAFT::_build_got ({ got => got { 'foo' } })
	=> expect => +{
		error    => '',
		lives_ok => expect_true,
		value    => "foo",
	};

it "should catch exception thrown by got { } block"
	=> got    => Test::YAFT::_build_got ({ got => got { die bless {}, 'Foo::Bar' } })
	=> expect => +{
		error    => expect_isa ('Foo::Bar'),
		lives_ok => expect_false,
		value    => undef,
	};

had_no_warnings;

done_testing;
