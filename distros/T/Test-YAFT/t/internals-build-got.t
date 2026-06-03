#!/usr/bin/env perl

use v5.14;
use  warnings;

use require::relative q (test-helper.pl);

it q (should build result from non-coderef)
	=> got    => Test::YAFT::_build_got ({ got => q (foo) })
	=> expect => +{
		error    => undef,
		lives_ok => expect_true,
		value    => q (foo),
	};

it q (should execute coderef)
	=> got    => Test::YAFT::_build_got ({ got => sub { q (foo) } })
	=> expect => +{
		error    => q (),
		lives_ok => expect_true,
		value    => q (foo),
	};

it q (should execute coderef in scalar context)
	=> got    => Test::YAFT::_build_got ({ got => sub { qw[ foo bar ] } })
	=> expect => +{
		error    => q (),
		lives_ok => expect_true,
		value    => q (bar),
	};

it q (should catch exception thrown by coderef)
	=> got    => Test::YAFT::_build_got ({ got => sub { die bless {}, q (Foo::Bar) } })
	=> expect => +{
		error    => expect_isa (q (Foo::Bar)),
		lives_ok => expect_false,
		value    => undef,
	};

it q (should execute got { } block)
	=> got    => Test::YAFT::_build_got ({ got => got { q (foo) } })
	=> expect => +{
		error    => q (),
		lives_ok => expect_true,
		value    => q (foo),
	};

it q (should catch exception thrown by got { } block)
	=> got    => Test::YAFT::_build_got ({ got => got { die bless {}, q (Foo::Bar) } })
	=> expect => +{
		error    => expect_isa (q (Foo::Bar)),
		lives_ok => expect_false,
		value    => undef,
	};

had_no_warnings;

done_testing;
