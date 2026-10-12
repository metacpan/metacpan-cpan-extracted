#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Test::NoShadow') || print 'Bail out!';
}

require_ok('Test::NoShadow') || print 'Bail out!';

diag("Testing Test::NoShadow $Test::NoShadow::VERSION, Perl $], $^X");
