#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

frame {
	act { [ @_ ] } qw[ foo bar ];

	arrange { foo => 'foo-1' };
	arrange { bar => 'bar-1' };

	it "should provide frame act { } block dependencies"
		=> expect => [ 'foo-1', 'bar-1' ]
		;

	it "should override act { } block dependencies per it"
		=> arrange { foo => 'foo-2' }
		=> expect => [ 'foo-2', 'bar-1' ]
		;

	it "should accept multiple arrange { } blocks"
		=> arrange { foo => 'foo-2' }
		=> arrange { bar => 'bar-2' }
		=> expect => [ 'foo-2', 'bar-2' ]
		;
};

had_no_warnings;

done_testing;
