#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Test::Most::Explain') || print 'Bail out!';
}

require_ok('Test::Most::Explain') || print 'Bail out!';

diag("Testing Test::Most::Explain $Test::Most::Explain::VERSION, Perl $], $^X");
