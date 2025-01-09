#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Test::Mockingbird') || print 'Bail out!';
}

require_ok('Test::Mockingbird') || print 'Bail out!';

diag("Testing Test::Mockingbird $Test::Mockingbird::VERSION, Perl $], $^X");
