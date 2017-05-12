# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('WWW::Search::Antikvariat11CZ');
}

# Test.
require_ok('WWW::Search::Antikvariat11CZ');
