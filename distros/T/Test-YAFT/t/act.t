#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

subtest "act { } block can specify implicit got value builder" => sub {
	my $iterator = [ 42 ];

	act { push @$iterator, $iterator->[-1] + 1; $iterator->[-1] };

	it "should not execute act { } block when got is specified"
		=> got    => $iterator
		=> expect => [ 42 ]
		;

	it "should execute act { } block to build contextual got"
		=> expect => 43
		;

	it "should have side effects"
		=> got    => $iterator
		=> expect => [ 42, 43 ]
		;
};

frame {
	act { [ @_ ] } qw[ foo bar ];

	proclaim foo => 'foo-1';
	proclaim bar => 'bar-1';

	it "should execute act { } block with specified dependencies (as arguments)"
		=> expect => [ 'foo-1', 'bar-1' ]
		;
};

frame {
	act { [ @_ ] } qw[ foo2 bar2 aaa2 ];

	proclaim foo2 => 'foo-2';

	it "should throw exception with missing dependencies"
		=> throws => 'Act dependencies not fultified: aaa2, bar2'
		;
};

frame {
	act { die "Exception foo" };

	it "should catch exception thrown by act { } block"
		=> throws => expect_re (qr/^Exception foo at /)
		;
};

frame {
	act { die "foo" };

	it "should not call act { } block when explicit got is specified"
		=> got    => 1
		=> expect => 1
		;
};

had_no_warnings;

done_testing;
