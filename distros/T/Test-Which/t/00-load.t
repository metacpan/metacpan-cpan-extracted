#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Test::Which') || print 'Bail out!';
}

require_ok('Test::Which') || print 'Bail out!';

diag("Testing Test::Which $Test::Which::VERSION, Perl $], $^X");
