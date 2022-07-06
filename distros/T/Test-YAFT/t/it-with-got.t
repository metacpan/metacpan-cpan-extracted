#!/usr/bin/env perl

use v5.14;
use  warnings;

use require::relative "test-helper.pl";

subtest "should build tested value using got { } block" => sub {
	check_test {
		it "got { } block"
			=> got    => got { "foo" }
			=> expect => "foo"
			;
	}
	ok          => 1,
	actual_ok   => 1,
	name        => 'got { } block',
	diag        => '',
};

subtest "should recognize got { } block also without named parameter" => sub {
	check_test {
		it "got { } block"
			=> got { "foo" }
			=> expect => "foo"
			;
	}
	ok          => 1,
	actual_ok   => 1,
	name        => 'got { } block',
	diag        => '',
};

subtest "should test expected failure" => sub {
	check_test {
		it "got { } block"
			=> got { die bless [ 'foo' ], 'Foo::Bar' }
			=> throws => expect_isa ('Foo::Bar')
			;
	}
	ok          => 1,
	actual_ok   => 1,
	name        => 'got { } block',
	diag        => '',
};

subtest "should fail when expect 'throws' but code lives" => sub {
	check_test {
		it "got { } block"
			=> got { "foo" }
			=> throws => ignore
			;
	}
	ok          => 0,
	actual_ok   => 0,
	name        => 'got { } block',
	diag        => <<'DIAG',
Expected to die by lives
DIAG
};

subtest "should fail when not expecting 'throws' but code dies" => sub {
	check_test {
		it "got { } block"
			=> got { die "foo" }
			=> expect => ignore
			;
	}
	ok          => 0,
	actual_ok   => 0,
	name        => 'got { } block',
	diag        => qr/Expected to live but died/,
};

had_no_warnings;

done_testing;
