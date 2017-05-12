#!perl

use Test::Tester;
use Test::More tests => 1;
use Test::Output;

use strict;
use warnings;


eval {
	stdout_is(
		sub { binmode STDOUT; print 'foo'; },
		'foo',
		"The binmode doesn't blow up"
		);
	};
